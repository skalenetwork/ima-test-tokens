// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   ERC20Wrap.sol - SKALE Test tokens
 *   Copyright (C) 2022-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";

contract ERC20Wrap is ERC20Wrapper {

    constructor(
        string memory contractName,
        string memory contractSymbol,
        IERC20 originToken
    )
        ERC20Wrapper(originToken)
        ERC20(contractName, contractSymbol)
    {
        
    }
}