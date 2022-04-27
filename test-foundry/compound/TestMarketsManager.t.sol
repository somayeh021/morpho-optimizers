// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.13;

import "./setup/TestSetup.sol";

contract TestMarketsManager is TestSetup {
    using CompoundMath for uint256;

    function testShoudDeployContractWithTheRightValues() public {
        assertEq(
            marketsManager.p2pSupplyIndex(cDai),
            2 * 10**(16 + IERC20Metadata(ICToken(cDai).underlying()).decimals() - 8)
        );
        assertEq(
            marketsManager.p2pBorrowIndex(cDai),
            2 * 10**(16 + IERC20Metadata(ICToken(cDai).underlying()).decimals() - 8)
        );
    }

    function testShouldRevertWhenCreatingMarketWithAnImproperMarket() public {
        hevm.expectRevert(MarketsManager.MarketCreationFailedOnCompound.selector);
        marketsManager.createMarket(address(supplier1));
    }

    function testOnlyOwnerCanCreateMarkets() public {
        for (uint256 i = 0; i < pools.length; i++) {
            hevm.expectRevert("Ownable: caller is not the owner");
            supplier1.createMarket(pools[i]);

            hevm.expectRevert("Ownable: caller is not the owner");
            borrower1.createMarket(pools[i]);
        }

        marketsManager.createMarket(cAave);
    }

    function testOnlyOwnerCanSetReserveFactor() public {
        for (uint256 i = 0; i < pools.length; i++) {
            hevm.expectRevert("Ownable: caller is not the owner");
            supplier1.setReserveFactor(cDai, 1111);

            hevm.expectRevert("Ownable: caller is not the owner");
            borrower1.setReserveFactor(cDai, 1111);
        }

        marketsManager.setReserveFactor(cDai, 1111);
    }

    function testReserveFactorShouldBeUpdatedWithRightValue() public {
        marketsManager.setReserveFactor(cDai, 1111);
        (uint16 reserveFactor, ) = marketsManager.marketParameters(cDai);
        assertEq(reserveFactor, 1111);
    }

    function testPositionsManagerShouldBeSetOnlyOnce() public {
        hevm.expectRevert(MarketsManager.PositionsManagerAlreadySet.selector);
        marketsManager.setPositionsManager(address(fakePositionsManagerImpl));
    }

    function testShouldCreateMarketWithTheRightValues() public {
        ICToken cToken = ICToken(cAave);
        marketsManager.createMarket(cAave);

        assertTrue(marketsManager.isCreated(cAave));
        assertEq(
            marketsManager.p2pSupplyIndex(cAave),
            2 * 10**(16 + IERC20Metadata(cToken.underlying()).decimals() - 8)
        );
        assertEq(
            marketsManager.p2pBorrowIndex(cAave),
            2 * 10**(16 + IERC20Metadata(cToken.underlying()).decimals() - 8)
        );
    }

    function testShouldSetmaxGasWithRightValues() public {
        PositionsManagerStorage.MaxGasForMatching memory newMaxGas = PositionsManagerStorage
        .MaxGasForMatching({supply: 1, borrow: 1, withdraw: 1, repay: 1});

        positionsManager.setMaxGasForMatching(newMaxGas);
        (uint64 supply, uint64 borrow, uint64 withdraw, uint64 repay) = positionsManager
        .maxGasForMatching();
        assertEq(supply, newMaxGas.supply);
        assertEq(borrow, newMaxGas.borrow);
        assertEq(withdraw, newMaxGas.withdraw);
        assertEq(repay, newMaxGas.repay);

        hevm.expectRevert("Ownable: caller is not the owner");
        supplier1.setMaxGasForMatching(newMaxGas);

        hevm.expectRevert("Ownable: caller is not the owner");
        borrower1.setMaxGasForMatching(newMaxGas);
    }

    function testOnlyOwnerCanSetMaxSortedUsers() public {
        uint256 newMaxSortedUsers = 30;

        positionsManager.setMaxSortedUsers(newMaxSortedUsers);
        assertEq(positionsManager.maxSortedUsers(), newMaxSortedUsers);

        hevm.expectRevert("Ownable: caller is not the owner");
        supplier1.setMaxSortedUsers(newMaxSortedUsers);

        hevm.expectRevert("Ownable: caller is not the owner");
        borrower1.setMaxSortedUsers(newMaxSortedUsers);
    }

    function testOnlyOwnerShouldFlipMarketStrategy() public {
        hevm.expectRevert("Ownable: caller is not the owner");
        supplier1.setNoP2P(cDai, true);

        hevm.expectRevert("Ownable: caller is not the owner");
        supplier2.setNoP2P(cDai, true);

        marketsManager.setNoP2P(cDai, true);
        assertTrue(marketsManager.noP2P(cDai));
    }

    function testOnlyOwnerShouldBeAbleToUpdateInterestRates() public {
        IInterestRates interestRatesV2 = new InterestRatesV1();

        hevm.prank(address(0));
        hevm.expectRevert("Ownable: caller is not the owner");
        marketsManager.setInterestRates(interestRatesV2);

        marketsManager.setInterestRates(interestRatesV2);
        assertEq(address(marketsManager.interestRates()), address(interestRatesV2));
    }
}
