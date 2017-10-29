pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import './LandSell.sol';

contract TerraformLandSell is LandSell, Ownable {

  function TerraformLandSell(address _token) {
    token = BurnableToken(_token);

    // Start LAND and assign genesis parcel
    land = deployLand();
    land.assignNewParcel(msg.sender, buildTokenId(0, 0), '42');
  }

  function buy(uint x, uint y, string data, uint cost) public {
    _buyLand(x, y, data, msg.sender, msg.sender, cost);
  }

  function transferLandOwnership(address _newOwner) onlyOwner public {
    land.transferOwnership(_newOwner);
  }

  function deployLand() internal returns (Land) {
    return new Land();
  }

  function isValidLand(uint x, uint y) internal returns (bool) {
    return true;
  }
}
