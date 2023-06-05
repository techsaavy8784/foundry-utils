// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/StdJson.sol";

import "./mocks/ICounter.sol";

abstract contract CommonDeploymentTest is Test {
    string anvilPID;

    string constant CHAIN_ID = "9119";
    string constant RPC_URL = "http://127.0.0.1:8546";

    function test_deploy_contract() public {
        _runAnvil();
        _runDeployments();

        string memory path = string.concat("deployments", "/", CHAIN_ID, "/", getFileName(), ".json");

        string memory fileData = vm.readFile(path);

        bytes memory addr = stdJson.parseRaw(fileData, ".address");
        address counterAddr = abi.decode(addr, (address));

        uint256 forkId = vm.createFork(RPC_URL, 1);
        vm.selectFork(forkId);

        ICounter counter = ICounter(counterAddr);

        assertEq(
            counter.multiplier(),
            getMultiplier(),
            "Failed to deploy contract with proper constructor arguments"
        );

        counter.increment();
        counter.increment();

        assertEq(
            counter.someNumber(),
            2,
            "Failed to increment"
        );
    }

    function _runDeployments() internal {
        string[] memory cmds = new string[](7);
        cmds[0] = "forge";
        cmds[1] = "script";
        cmds[2] = getDeploymentScript();
        cmds[3] = "--ffi";
        cmds[4] = "--broadcast";
        cmds[5] = "--rpc-url";
        cmds[6] = RPC_URL;

        vm.ffi(cmds);
    }

    function _runAnvil() internal {
        string[] memory cmds = new string[](2);
        cmds[0] = "./bash/run-anvil.sh";

        bytes memory output = vm.ffi(cmds);

        anvilPID = string(output);

        console.log("Started an Anvil with PID: >>>>>>>> ", anvilPID);
    }

    function _killAnvil() internal {
        if (bytes(anvilPID).length != 0) {
            string[] memory cmds = new string[](3);
            cmds[0] = "kill";
            cmds[1] = "-9";
            cmds[2] = anvilPID;

            vm.ffi(cmds);

            anvilPID = "";

            console.log("Killed an Anvil with PID: >>>>>>>> ", anvilPID);
        }
    }

    function getFileName() internal pure virtual returns (string memory) {}

    function getDeploymentScript() internal pure virtual returns (string memory) {}

    function getMultiplier() internal pure virtual returns (uint256) {}
}
