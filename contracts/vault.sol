// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/iStrategy.sol";
import "./interfaces/iVaultEvents.sol";
import "./libraries/WithdrawalQueue.sol";
import "./libraries/AllocationMath.sol";

/**
 * @title MultiStrategyVault
 * @notice Production-grade ERC-4626 vault
 */
contract Vault is
    ERC4626,
    AccessControl,
    ReentrancyGuard,
    Pausable,
    IVaultEvents
{
    using WithdrawalQueue for WithdrawalQueue.Queue;
    using SafeERC20 for IERC20;


    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IStrategy[] public strategies;
    mapping(address => uint256) public strategyWeightBps;
    mapping(address => bool) public isStrategy;
    mapping(address => uint256) public strategyDebt;
    uint256 public totalWeightBps;



    WithdrawalQueue.Queue private queue;

    uint256 public constant MAX_STRATEGY_CAP = 5_000; // 50%

    constructor(IERC20 asset_)
        ERC20("Vault Share", "vUSDC")
        ERC4626(asset_)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
    IERC20 underlying = IERC20(asset());
    uint256 assets = underlying.balanceOf(address(this));

    uint256 len = strategies.length;
    for (uint256 i = 0; i < len; ) {
        assets += strategies[i].totalAssets();
        unchecked { ++i; }
    }

    return assets;
}

    /*//////////////////////////////////////////////////////////////
                        STRATEGY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function addStrategy(IStrategy strategy, uint256 weightBps)
        external
        onlyRole(MANAGER_ROLE)
    {
        IERC20 underlying = IERC20(asset());
        require(address(strategy) != address(0), "Zero address");
        require(!isStrategy[address(strategy)], "Already added");
        AllocationMath.checkCap(weightBps, MAX_STRATEGY_CAP);
        require(totalWeightBps + weightBps <= 10_000, "Total allocation exceeds 100%");
        strategies.push(strategy);
        isStrategy[address(strategy)] = true;
        strategyWeightBps[address(strategy)] = weightBps;
        totalWeightBps += weightBps;
        underlying.forceApprove(address(strategy), type(uint256).max);
        emit StrategyAdded(address(strategy), weightBps);
    }

    function simulateStrategyYield(address strategy, uint256 amount)
    external
    onlyRole(MANAGER_ROLE)
{
    require(isStrategy[strategy], "Not a strategy");
    IStrategy(strategy).simulateYield(amount);
}

    function _deposit(
    address caller,
    address receiver,
    uint256 assets,
    uint256 shares
   ) internal override {
    super._deposit(caller, receiver, assets, shares);

    // Route capital AFTER ERC-4626 accounting is complete
    _routeCapital();
  }


    /*//////////////////////////////////////////////////////////////
                        WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/


    function _routeCapital() internal {
    IERC20 underlying = IERC20(asset());
    uint256 total = totalAssets();

    uint256 len = strategies.length;
    for (uint256 i = 0; i < len; ) {
        IStrategy strategy = strategies[i];

        uint256 target =
            AllocationMath.computeTarget(
                total,
                strategyWeightBps[address(strategy)]
            );

        uint256 current = strategyDebt[address(strategy)];

        if (current < target) {
            uint256 delta = target - current;
            uint256 idle = underlying.balanceOf(address(this));
            uint256 toDeposit = delta > idle ? idle : delta;

            if (toDeposit > 0) {
                
                strategy.deposit(toDeposit);
                strategyDebt[address(strategy)] += toDeposit;
                emit StrategyDebtUpdated(address(strategy), strategyDebt[address(strategy)]);

            }
        }
        unchecked { ++i; }
    }
}
    function rebalance()
    external
    onlyRole(MANAGER_ROLE)
    nonReentrant
{
    IERC20 underlying = IERC20(asset());
    uint256 total = totalAssets();

    uint256 len = strategies.length;
for (uint256 i = 0; i < len; ) {
    IStrategy strategy = strategies[i];

    uint256 target =
        AllocationMath.computeTarget(
            total,
            strategyWeightBps[address(strategy)]
        );

    uint256 current = strategyDebt[address(strategy)];

    if (current > target) {
        uint256 excess = current - target;
        uint256 liquid = strategy.maxWithdraw();
        uint256 toWithdraw = excess > liquid ? liquid : excess;

        if (toWithdraw > 0) {
            uint256 received = strategy.withdraw(toWithdraw);
            uint256 prevDebt = strategyDebt[address(strategy)];
            require(received <= prevDebt, "Strategy debt underflow");
            strategyDebt[address(strategy)] = prevDebt - received;
            emit StrategyDebtUpdated(address(strategy), strategyDebt[address(strategy)]);

            underlying.safeTransfer(address(this), received);
        }
    } else if (current < target) {
        uint256 delta = target - current;
        uint256 idle = underlying.balanceOf(address(this));
        uint256 toDeposit = delta > idle ? idle : delta;

        if (toDeposit > 0) {
            strategy.deposit(toDeposit);
            strategyDebt[address(strategy)] += toDeposit;
            emit StrategyDebtUpdated(address(strategy), strategyDebt[address(strategy)]);
        }
    }

    unchecked { ++i; }
}

emit Rebalanced();
}




    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override nonReentrant whenNotPaused returns (uint256 shares) {
        IERC20 underlying = IERC20(asset());
        shares = previewWithdraw(assets);
        if (msg.sender != owner) {
        _spendAllowance(owner, msg.sender, shares);
    }

        _burn(owner, shares);

        uint256 remaining = assets;

        uint256 idle = underlying.balanceOf(address(this));
        if (idle > 0) {
            uint256 pay = idle > remaining ? remaining : idle;
            underlying.safeTransfer(receiver, pay);
            remaining -= pay;
        }

        uint256 len = strategies.length;
        for (uint256 i = 0; i < len && remaining > 0; ) {
            uint256 liquid = strategies[i].maxWithdraw();
            if (liquid == 0) {
            unchecked { ++i; }
             continue;
        }


            uint256 pull = liquid > remaining ? remaining : liquid;
            uint256 got = strategies[i].withdraw(pull);
            uint256 prevDebt = strategyDebt[address(strategies[i])];
            require(got <= prevDebt, "Strategy debt underflow");
            strategyDebt[address(strategies[i])] = prevDebt - got;
            emit StrategyDebtUpdated(address(strategies[i]), strategyDebt[address(strategies[i])]);


            underlying.safeTransfer(receiver, got);
            remaining -= got;
            unchecked { ++i; }
        }

        if (remaining > 0) {
            uint256 unlock = block.timestamp + 3 days;
            queue.enqueue(receiver, remaining, unlock);
            emit WithdrawalQueued(receiver, remaining, unlock);
        }
    }

    function claim(uint256 requestId) external nonReentrant {
        (address user, uint256 amount) = queue.claim(requestId);
        IERC20(asset()).safeTransfer(user, amount);
        emit Claimed(user, amount);
    }
}
