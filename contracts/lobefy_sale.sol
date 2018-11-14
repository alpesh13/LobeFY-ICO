pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
}


/**
 * @title LobefyCrowdsale
 * @dev 
 */
contract LobefyCrowdsale is Ownable {
    
    using SafeMath for uint256;
    
    event TokenPurchase(address indexed to, uint256 amount);
    event InitialRateChange(uint256 rate);
    
    ERC20   private _token;             // The token being sold
    address private _wallet;            // Address where funds are collected
    uint256 private _rate = 3000;       // How many token units investor gets per wei
    uint256 private _weiRaised;         // Amount of wei raised
    uint256 private _tokensSold;        // Amount of tokens sold
    bool    private _paused = false;    // Sale is open by default (use toggle to change)
    
    
    // Statistics
    
    uint256 private soldPhaseone;
    uint256 private soldPhaseTwo;
    uint256 private soldPhaseThree;
  
  
    // Dates
    
    uint256 public phaseOneStart    = now;                //11/05/2018 @ 6:00am (UTC) @ 00:00 am CST
    uint256 public phaseOneEnd      = phaseOneStart + 15 days;
    
    uint256 public phaseTwoStart    = phaseOneEnd +1 seconds;
    uint256 public phaseTwoEnd      = phaseTwoStart + 15 days;
    
    uint256 public phaseThreeStart  = phaseTwoEnd + 1 seconds;
    uint256 public phaseThreeEnd    = phaseThreeStart + 15 days;
    
    
    // -----------------------------------------
    // Crowdsale Controllers
    // -----------------------------------------
    
    /**
     * @dev modifier to prevent transections when sale is used/closed
     * Checks, if ICO is running and has not been stopped
     */
    modifier onSaleRunning() {
        require(!_paused && now >= phaseOneStart && now <= phaseThreeEnd);
        _;
    }
    
    /**
     * @dev sale switch (pause/unpause)
     * @param pause_unpause - sale status (true/false)
     */
    function saleSwitch(bool pause_unpause) onlyOwner public returns(bool) {
        _paused = pause_unpause;
        
    }
    
    /**
     * @dev token rate change
     * @param newRate - new rate value
     */
    function changeRate(uint256 newRate) public onlyOwner returns (bool) {
        _rate = newRate;

        emit InitialRateChange(_rate);
        return true;
    }
    
    /**
     * @dev wallet change
     * @param newWallet - new wallet address
     */
    function changeWallet(address newWallet) public onlyOwner returns (bool) {
        _wallet = newWallet;
        return true;
    }
    
   

    /**
     * @dev token crowdsale Constructor
 
     * @param wallet - Address where collected funds will be forwarded to
     * @param token - Address of the token being sold
     */
    constructor(address wallet, ERC20 token) public {
        require(wallet != address(0));
        require(token != address(0));
        
        _wallet = wallet;
        _token = token;
    }
    
    
    
    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------
    
    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    function () external onSaleRunning payable {
        revert();
    }
    
    /**
     * @return the token being sold.
     */
    function token() public view returns(ERC20) {
        return _token;
    }
    
    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns(address) {
        return _wallet;
    }
    
    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns(uint256) {
        return _rate;
    }
    
    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }
    
    /**
     * @return the amount of tokens sold.
     */
    function tokensSold() public view returns (uint256) {
        return _tokensSold;
    }
    
    /**
     * @return returns sale status,, true if paused and false if sale is active
     */
    function salePaused() public view returns(bool) {
        return _paused;
    }
    
    /**
     * @return the amount of tokens sold on specific stage
     */
     
    function _soldPhaseone() public view returns (uint256) {
        return soldPhaseone;
    }
    function _soldPhaseTwo() public view returns (uint256) {
        return soldPhaseTwo;
    }
    function _soldPhaseThree() public view returns (uint256) {
        return soldPhaseThree;
    }
    
    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     */
    function buyTokens(address investor, bytes32 messsageHash, bytes signature) public payable onSaleRunning{
        uint256 weiAmount = msg.value;
        _preValidatePurchase(investor, weiAmount, messsageHash, signature);
        uint256 tokens = _getTokenAmount(weiAmount);
      
        _processPurchase(investor, tokens);
        _forwardFunds(weiAmount);
        
        _weiRaised = _weiRaised.add(weiAmount);
        _tokensSold = _tokensSold.add(tokens);
        
        _updateStageStates(tokens);
        
        emit TokenPurchase(investor, tokens);
    }
  
  
    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------
    
    // Pre validation
    
    function _preValidatePurchase(address investor, uint256 weiAmount, bytes32 messsageHash, bytes signature) internal view {
        require(investor != address(0));
        require(weiAmount != 0);
        address ownerAddress = recover(messsageHash, signature);
        require (ownerAddress == owner);
    }
    
    // Get token amount and bonuses
    
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 bonusRate;
        if (now >= phaseOneStart && now <=phaseOneEnd) {
            bonusRate = _rate.mul(2);
            return weiAmount.mul(bonusRate);
        }
            else if (now >= phaseTwoStart && now <=phaseTwoEnd) {
                bonusRate = _rate.add((_rate.mul(5)).div(10));
                return weiAmount.mul(bonusRate);
            }
                else {
                    return weiAmount.mul(_rate);
                }
    }
    
    
    // Token transfer

    function _processPurchase(address investor, uint256 tokenAmount) public {
        _token.transfer(investor, tokenAmount);
    }
    
    
    // Raised Ether transfer
    
    function _forwardFunds(uint256 weiAmount) internal {
        _wallet.transfer(weiAmount);
    }
    
    
    // Update statistics
    
    function _updateStageStates(uint256 tokens) internal{
        if (now >= phaseOneStart && now <=phaseOneEnd) {
            soldPhaseone = soldPhaseone.add(tokens);
            }   else if (now >= phaseTwoStart && now <=phaseTwoEnd) {
                    soldPhaseTwo = soldPhaseTwo.add(tokens);
                }   else {
                        soldPhaseThree = soldPhaseThree.add(tokens);
                    }
    }
    
    
    function recover(bytes32 hash, bytes sig) public pure returns (address) {
      bytes32 r;
      bytes32 s;
      uint8 v;

      //Check the signature length
      if (sig.length != 65) {
        return (address(0));
      }

      // Divide the signature in r, s and v variables
      assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
      }

      // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
      if (v < 27) {
        v += 27;
      }

      // If the version is correct return the signer address
      if (v != 27 && v != 28) {
        return (address(0));
      } else {
        return ecrecover(hash, v, r, s);
      }
    }
    
    
    function retriveBalance() public onlyOwner {
        uint256 contractBalance = _token.balanceOf(this);
        _token.transfer(owner, contractBalance);
    }
    
}