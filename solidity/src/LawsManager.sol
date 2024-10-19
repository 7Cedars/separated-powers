// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ILawsManager} from "./interfaces/ILawsManager.sol"; 
import {ILaw} from "./interfaces/ILaw.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

 /**
 * @notice Contract to manage laws in the SeparatedPowers protocol. 
 *
 * @dev This libary only manages setting law address to true and false + some getters. 
 * Laws are contracts of their own that need to be deployed through their own constructor functions. 
 *  
 */
contract LawsManager is ILawsManager {
  error LawsManager__NotAuthorized(); 
  error LawsManager__IncorrectInterface(address law);
  
  mapping(address law => bool active) public activeLaws; 
  
  event LawSet(address indexed law, bool indexed active, bool indexed lawChanged);
  
  /**
  * @dev {see ILawsManager.setLaw} 
  */
  function setLaw(address law, bool active) public { 
    // check is caller the protocol? 
    if (msg.sender != address(this)) { 
      revert LawsManager__NotAuthorized();  
    }

    _setLaw(law, active);
  } 

  /**
  * @notice internal function to set a law to active or inactive.
  * 
  * @param law address of the law.
  * @param active bool to set the law to active or inactive.
  *
  * @dev this function can only be called from the execute function of SeperatedPowers.sol. 
  * 
  * returns bool lawChanged, true if the law is set as active.
  *
  * emits a LawSet event. 
  */
  function _setLaw(address law, bool active) internal virtual returns (bool lawChanged) { 
    // check if added address is indeed a law   
    if (!ERC165Checker.supportsInterface(law, type(ILaw).interfaceId)) {
      revert LawsManager__IncorrectInterface(law);
    }

    lawChanged = (activeLaws[law] != active); 
    if (lawChanged) activeLaws[law] = active; 

    emit LawSet(law, active, lawChanged);
    return lawChanged; 
  } 

  /**
  * @dev {see ILawsManager.getActiveLaw} 
  */
  function getActiveLaw(address law) external view returns (bool active) { 
    return activeLaws[law]; 
  }
}