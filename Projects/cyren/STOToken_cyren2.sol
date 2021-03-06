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
    
    bool public freeMintingMode = false;
    bool public firstSaleMode = true;
    uint256 private _minTokenMint;
    
    event SwapTokens(address indexed from, address indexed to, uint256 tokens);

    function initialize(string memory name, string memory symbol, uint256 supply) public {
      __STOToken_init(name, symbol, supply);
    }

    function __STOToken_init(string memory name, string memory symbol, uint256 supply) internal initializer {
      __Context_init_unchained();
      __AccessControl_init_unchained();
      __ERC20_init_unchained(name, symbol);
      __ERC20Whitelisted_init();
      __ERC20Capped_init(supply);
      __Pausable_init_unchained();
      __ERC20Pausable_init_unchained();
      __STOToken_init_unchained(supply);
    }

    function __STOToken_init_unchained(uint256 supply) internal initializer {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(MINTER_ROLE, _msgSender());
      _setupRole(PAUSER_ROLE, _msgSender());
      _minTokenMint = supply.div(100);
    }


    function grantMinterRole(address minterAddress) public onlyOwner {
      grantRole(MINTER_ROLE, minterAddress);
    }

    function grantPauserRole(address pauserAddress) public onlyOwner {
      grantRole(PAUSER_ROLE, pauserAddress);
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
      
      if(totalSupply().add(amount) == cap()){
        firstSaleMode = false;
      }
    
      if(!freeMintingMode){
          require(amount >= _minTokenMint , "Amount is less than minimum allowed value" );
      }
      
      _mint(to, amount);
    }
    
    function burn(address account, uint256 amount) public onlyOwner {
       uint256 tokenUnitValue = uint256(10**18);
       require(balanceOf(account).mod(tokenUnitValue) != 0, "You are not allowed to burn non-integer values");
       _burn(account, amount);
    }
    
    function setFreeMintingMode(bool mode) public onlyOwner {
      freeMintingMode = mode;
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
      
      if(from != address(0) && to != address(0)){
        if(firstSaleMode){
            require(amount == balanceOf(from), "You can only transfer all the tokens in first sale");
        }
        
        require(amount.mod(tokenUnitValue) == 0 , "Amount must be an integer");
      } 
      
    }

    uint256[50] private __gap;
}
