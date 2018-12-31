pragma solidity ^0.4.24;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract Escrow is Pausable, Ownable {
    event CounterPartySet(address indexed counterParty);
    event OwnerSetTerms(address indexed owner);
    event OwnerTransferredAsset(address indexed contractOwner, address contractAddress, uint256 assetId, uint256 contractBalance);
    event OwnerWithdrewAsset(address indexed owner, uint256 assetId);
    event CounterPartyDeposited(address indexed counterParty, uint256 depositAmount);
    event CounterPartyRemoved(address indexed counterParty, uint256 contractBalance);
    event WithdrawalsLocked(address indexed payee, uint256 amount, uint256 balance);
    event DisburseHoldings(address indexed owner, uint256 paymentAmount, address counterParty, uint256 assetId, uint256 contractBalance);

    address public owner;
    address public counterParty;
    ERC721 public assetAddress;
    uint256 public priceMana;
    ERC721 public priceCounterPartyAsset;

    constructor(address _assetAddress, address _priceCounterPartyAsset, uint256 _priceMana) public {
        require(_assetAddress != address(0) && _assetAddress != address(this));
        require(_priceMana > 0 || _priceCounterPartyAsset != address(0));

        owner = address(msg.sender);
        assetAddress = ERC721(_assetAddress);
        priceMana = _priceMana;
        priceCounterPartyAsset = ERC721(_priceCounterPartyAsset);
    }

    modifier onlyCounterParty() {
        require(msg.sender == counterParty);
        _;
    }

    function setCounterParty(address _counterParty) public onlyOwner {
        counterParty = _counterParty;
        emit CounterPartySet(counterParty);
    }

    function getCounterParty() public view returns(address _counterParty) {
         return counterParty;
    }

    function removeCounterParty() public onlyOwner {
        require(address(this).balance == 0);
        address removedCounterParty = counterParty;
        counterParty = address(0);
        emit CounterPartyRemoved(removedCounterParty, address(this).balance);
    }

    function depositAsset(uint256 _assetId) public payable onlyOwner whenNotPaused {
        address assetSeller = assetAddress.ownerOf(_assetId);
        assetAddress.safeTransferFrom(assetSeller, address(this), _assetId);
        emit OwnerTransferredAsset(assetSeller, address(this), _assetId, address(this).balance);
    }

    // Pause during withdrawal
    function withdrawAsset() public view onlyOwner {
        require(address(this).balance == 0);

    }

    function counterPartyDeposit(uint256 _assetId, address _counterPartyAsset) public payable onlyCounterParty whenNotPaused {
        /*
        * Under construction - Look into reentrancy attack with accepting eth
        */
        require(msg.sender != address(0) && msg.sender != address(this));
        require(msg.value >= priceMana);
        // require(assetAddress.exists(_assetId)); // validation not workin
        // validate _counterPartyAsset

        // move next line to disburseHoldings
        assetAddress.safeTransferFrom(address(this), msg.sender, _assetId);

        //account for ERC721 deposits as well
        emit CounterPartyDeposited(msg.sender, msg.value);
    }

    function disburseHoldings(address _payee, uint256 _amount) public onlyCounterParty {
      /*
      * Pause contract while price is being updated, pause library not workin Remix IDE
      */
        require(_payee != address(0) && _payee != address(this));
        require(_amount > 0 && _amount <= address(this).balance);

        _payee.transfer(_amount);
    }

    function setPrice(uint256 _priceMana, address _counterPartyAsset) public onlyOwner {
        /*
      * Pause contract while price is being updated, pause library not workin Remix IDE
      */
        require(_priceMana > 0);
        // Requires more filtering/validation of _counterPartyAssets

        // Old asset/price for emiting event metadata - currently unussed
        ERC721 oldCounterPartyAsset = ERC721(priceCounterPartyAsset);
        priceCounterPartyAsset = ERC721(_counterPartyAsset);
        uint256 oldPrice = priceMana;
        priceMana = _priceMana;
    }
}
