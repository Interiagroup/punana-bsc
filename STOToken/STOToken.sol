// Inspired on https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/presets/ERC20PresetMinterPauserUpgradeable.sol
// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v3.4/contracts/access/AccessControlUpgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v3.4/contracts/utils/ContextUpgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v3.4/contracts/token/ERC20/ERC20PausableUpgradeable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v3.4/contracts/token/ERC20/ERC20CappedUpgradeable.sol";

import "./ERC20Whitelisted.sol";

contract STOToken is ContextUpgradeable, AccessControlUpgradeable, ERC20Whitelisted, ERC20CappedUpgradeable, ERC20PausableUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint8 private _maxPoolPercent;
    uint8 private _minPoolPercent;
    uint8 public _sharesByToken;
    uint8 private _maxTokenMint;
    uint8 private _minTokenMint;
    uint256 private _shareValue;
    
    event SwapTokens(address indexed from, address indexed to, uint256 tokens);

    function initialize(string memory name, string memory symbol, uint256 supply, uint8 minPoolPercent, uint8 maxPoolPercent, uint8 sharesByToken, uint8 maxTokenMint, uint8 minTokenMint) public {
      __STOToken_init(name, symbol, supply, minPoolPercent, maxPoolPercent, sharesByToken, maxTokenMint, minTokenMint);
    }

    function __STOToken_init(string memory name, string memory symbol, uint256 supply, uint8 minPoolPercent, uint8 maxPoolPercent, uint8 sharesByToken, uint8 maxTokenMint, uint8 minTokenMint) internal initializer {
      __Context_init_unchained();
      __AccessControl_init_unchained();
      __ERC20_init_unchained(name, symbol);
      __ERC20Whitelisted_init();
      __ERC20Capped_init(supply);
      __Pausable_init_unchained();
      __ERC20Pausable_init_unchained();
      __STOToken_init_unchained(minPoolPercent, maxPoolPercent, sharesByToken, maxTokenMint, minTokenMint);
    }

    function __STOToken_init_unchained(uint8 minPoolPercent, uint8 maxPoolPercent, uint8 sharesByToken, uint8 maxTokenMint, uint8 minTokenMint) internal initializer {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(MINTER_ROLE, _msgSender());
      _setupRole(PAUSER_ROLE, _msgSender());
      _minPoolPercent = minPoolPercent;
      _maxPoolPercent = maxPoolPercent;
      _sharesByToken = sharesByToken;
      _maxTokenMint = maxTokenMint;
      _minTokenMint = minTokenMint;
      
      uint256 safeDecimals = uint256(10**18);
      _shareValue = safeDecimals.div(sharesByToken);
    }

    function fullySold() public view returns(bool){
      uint256 cap = cap();

      if (totalSupply() >= cap.sub(cap.mul(_maxPoolPercent).div(100))) {
        return true;
      }
      return false;
    }

    function couldReceiveContribution(uint256 tokens) public view returns(bool){
      uint256 cap = cap();
      if (cap.sub(cap.mul(_minPoolPercent).div(100)) >= totalSupply().add(tokens)) {
        return true;
      }
      return false;
    }

    function grantMinterRole(address minterAddress) public onlyOwner {
      grantRole(MINTER_ROLE, minterAddress);
    }

    function grantPauserRole(address pauserAddress) public onlyOwner {
      grantRole(PAUSER_ROLE, pauserAddress);
    }

    function getPoolTokens() public onlyOwner {
      _mint(_msgSender(), cap().sub(totalSupply()));
    }

    function getPoolTokensByAmount(uint256 amount) public onlyOwner {
      require(cap().sub(totalSupply()) >= amount, "STOToken: not enough funds");
      _mint(_msgSender(), amount);
    }

    function swapTokens(address _from, address _to) public onlyOwner {
      require(_from != address(0), "STOToken: _from address is the zero address");
      require(_to != address(0), "STOToken: _from address is the zero address");
      require(balanceOf(_from) > 0, "STOToken: no tokens to transfer");

      uint256 fromBalance = balanceOf(_from);
      _transfer(_from, _to, fromBalance);

      emit SwapTokens(_from, _to, fromBalance);
    }

    function mint(address to, uint256 amount) public {
      require(hasRole(MINTER_ROLE, _msgSender()), "STOToken: must have minter role to mint");
      require(!fullySold(), "STOToken: Token fully sold");
      require(couldReceiveContribution(amount), "STOToken: tokens reserved for pool");
      
      uint256 safeDecimals = uint256(10**18);
      
      require(amount >= safeDecimals.mul(_minTokenMint) , "Amount is less than minimum allowed value" );
      require(amount <= safeDecimals.mul(_maxTokenMint) , "Amount exceeds maximum allowed value" );
      _mint(to, amount);
    }

    function pause() public {
      require(hasRole(PAUSER_ROLE, _msgSender()), "STOToken: must have pauser role to pause");
      _pause();
    }

    function unpause() public {
      require(hasRole(PAUSER_ROLE, _msgSender()), "STOToken: must have pauser role to unpause");
      _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Whitelisted, ERC20CappedUpgradeable, ERC20PausableUpgradeable) {
      super._beforeTokenTransfer(from, to, amount);
      uint256 tokenUnitValue = uint256(10**18);
      require(amount.mod(_shareValue) == 0 , "Amount must be a value that represents an integer shares number" );
      require(balanceOf(to).add(amount) >= tokenUnitValue, "The receiver must own more than 1 token");
     
    }

    uint256[50] private __gap;
}
