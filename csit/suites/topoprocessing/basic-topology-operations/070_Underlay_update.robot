*** Settings ***
Documentation     Test suite to verify update behaviour during different topoprocessing operations on NT and inventory models.
...               Before test starts, configurational file have to be rewriten to change listners registration datastore type from CONFIG_API to OPERATIONAL_API.
...               Need for this change is also a reason why main feature (odl-topoprocessing-framework) is installed after file change and not during boot.
...               Suite setup also installs features required for tested models and clears karaf logs for further synchronization. Tests themselves send configurational
...               xmls and verify output. Topology-id on the end of each urls must match topology-id from xml. Yang models of components in topology are defined in xmls.
Suite Setup       Setup Environment
Suite Teardown    Clean Environment
Test Teardown     Test Teardown With Underlay Topologies Refresh    network-topology:network-topology/topology/topo:1
Library           RequestsLibrary
Library           SSHLibrary
Library           XML
Variables         ../../../variables/topoprocessing/TopologyRequests.py
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TopoprocessingKeywords.robot

*** Test Cases ***
Unification Node Update
    [Documentation]    Test processing of updates using unification operation on Network Topology model
    #Create the original topology
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    network-topology-model    node    network-topo:1    network-topo:2
    ${request}    Insert Target Field    ${request}    0    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${request}    Insert Target Field    ${request}    1    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    8

    #Update a node, expecting a unification of two nodes into one
    ${node}    Create Isis Node    bgp:1    router-id-ipv4=192.168.1.2
    Basic Request Put    ${node}    network-topology:network-topology/topology/network-topo:1/node/bgp:1
    ${resp}    Basic Request Get And Test    ${node}    network-topology:network-topology/topology/topo:1    <node-id>node:    7
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Validate Supporting Node Node-Ref Content    ${resp}    bgp:2    bgp:1

    #Update a unified node, expecting creation of a new overlay node
    ${node}    Create Isis Node    bgp:3    router-id-ipv4=192.168.3.1
    Basic Request Put    ${node}    network-topology:network-topology/topology/network-topo:1/node/bgp:3
    ${resp}    Basic Request Get And Test    ${node}    network-topology:network-topology/topology/topo:1    <node-id>node:    8
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1

Unification Node Inventory
    [Documentation]    Test processing of updates using unification operation on Inventory model
    ${request}    Prepare Unification Topology Request    ${UNIFICATION_NT}    opendaylight-inventory-model    node    openflow-topo:1    openflow-topo:2
    ${request}    Insert Target Field    ${request}    0    flow-node-inventory:ip-address    0
    ${request}    Insert Target Field    ${request}    1    flow-node-inventory:ip-address    0
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    7

    #Update a node, expecting unification of two nodes into one
    ${node}    Create Openflow Node    openflow:2    192.168.1.1
    Basic Request Put    ${node}    opendaylight-inventory:nodes/node/openflow:2
    ${resp}    Basic Request Get And Test    ${node}    network-topology:network-topology/topology/topo:1    <node-id>node:    6
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    Validate Supporting Node Node-Ref Content    ${resp}    of-node:2    of-node:6    of-node:1

    #Update a unified node, expecting creation of a new overlay node
    ${node}    Create Openflow Node    openflow:4    192.168.3.1
    Basic Request Put    ${node}    opendaylight-inventory:nodes/node/openflow:4
    ${resp}    Basic Request Get And Test    ${node}    network-topology:network-topology/topology/topo:1    <node-id>node:    7
    : FOR    ${index}    IN RANGE    1    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1

Filtration Range Number Node Update Network Topology Model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    node    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ovsdb:ovs-version
    ${request}    Set Range Number Filter    ${request}    20    25
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    4
    ${request}    Create Isis Node    bgp:7    17
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:2/node/bgp:7
    ${resp}    Basic Request Get    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    : FOR    ${index}    IN RANGE    8    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Should Contain X Times    ${resp.content}    <termination-point>    3
    Should Not Contain    ${resp.content}    <node-ref>bgp:7</node-ref>
    Validate Supporting Node TP-Ref Content    ${resp}    network-topo:2    bgp:8    tp:8:1
    Validate Supporting Node TP-Ref Content    ${resp}    network-topo:2    bgp:9    tp:9:1
    Validate Supporting Node TP-Ref Content    ${resp}    network-topo:2    bgp:10    tp:10:1

    ${request}    Create Isis Node    bgp:7    23
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:2/node/bgp:7
    ${request}    Create OVSDB Termination Point    tp:7:1    1119
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:1
    ${resp}    Basic Request Get    network-topology:network-topology/topology/topo:1
    : FOR    ${index}    IN RANGE    7    11
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Should Contain X Times    ${resp.content}    <termination-point>    4
    Validate Supporting Node TP-Ref Content    ${resp}    network-topo:2    bgp:7    tp:7:1
    Validate Supporting Node TP-Ref Content    ${resp}    network-topo:2    bgp:8    tp:8:1
    Validate Supporting Node TP-Ref Content    ${resp}    network-topo:2    bgp:9    tp:9:1
    Validate Supporting Node TP-Ref Content    ${resp}    network-topo:2    bgp:10    tp:10:1

Filtration Range Number Node Update Inventory Model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    node    openflow-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    flow-node-inventory:serial-number
    ${request}    Set Range Number Filter    ${request}    20    25
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    ${request}    Create Openflow Node    openflow:7    192.168.2.3    23
    Basic Request Put    ${request}    opendaylight-inventory:nodes/node/openflow:7
    ${resp}    Basic Request Get    network-topology:network-topology/topology/topo:1
    : FOR    ${index}    IN RANGE    7    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    ${request}    Create Openflow Node    openflow:7    192.168.2.3    17
    Basic Request Put    ${request}    opendaylight-inventory:nodes/node/openflow:7
    ${resp}    Basic Request Get    network-topology:network-topology/topology/topo:1
    : FOR    ${index}    IN RANGE    8    11
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    Should Not Contain    ${resp.content}    <node-ref>of-node:7</node-ref>

Filtration Range Number Termination Point Update NT
    [Documentation]    Test processing of updates using range number type of filtration operation on Network Topology model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    termination-point    network-topo:2
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    ovsdb:ofport
    ${request}    Set Range Number Filter    ${request}    1115    1119
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5

    #Update a previously out-of-range termination point, so it passes filtration
    ${terminationPoint}    Create OVSDB Termination Point    tp:8:1    1115
    Basic Request Put    ${terminationPoint}    network-topology:network-topology/topology/network-topo:2/node/bgp:8/termination-point/tp:8:1
    ${resp}    Basic Request Get And Test    ${terminationPoint}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    4
    Validate Supporting Node TP-Ref Content    ${resp}    network-topo:2    bgp:8    tp:8:1

    #Update a previsouly in-range termination point, so it is filtered out
    ${terminationPoint}    Create OVSDB Termination Point    tp:7:2    1110
    Basic Request Put    ${terminationPoint}    network-topology:network-topology/topology/network-topo:2/node/bgp:7/termination-point/tp:7:2
    ${resp}    Basic Request Get And Test    ${terminationPoint}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    3
    Validate Supporting Node TP-Ref Content    ${resp}    network-topo:2    bgp:7    tp:7:1

Filtration Range Number Termination Point Update Inventory
    [Documentation]    Test processing of updates using range number type of filtration operation on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    termination-point    openflow-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    flow-node-inventory:port-number
    ${request}    Set Range Number Filter    ${request}    2    4
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    5

    #Update a previously out-of-range termination point, so it passes filtration
    ${nodeConnector}    Create Openflow Node Connector    openflow:2:1    3
    Basic Request Put    ${nodeConnector}    opendaylight-inventory:nodes/node/openflow:2/node-connector/openflow:2:1
    ${resp}    Basic Request Get And Test    ${nodeConnector}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    6
    Validate Supporting Node TP-Ref Content    ${resp}    openflow-topo:1    of-node:2    tp:3    tp:2:1    tp:2:2

    #Update an in-range termination point, so it is filtered out
    ${nodeConnector}    Create Openflow Node Connector    openflow:3:2    5
    Basic Request Put    ${nodeConnector}    opendaylight-inventory:nodes/node/openflow:3/node-connector/openflow:3:2
    ${resp}    Basic Request Get And Test    ${nodeConnector}    network-topology:network-topology/topology/topo:1    <node-id>node:    5
    Should Contain X Times    ${resp.content}    <termination-point>    5
    Validate Supporting Node TP-Ref Content    ${resp}    openflow-topo:1    of-node:3    tp:3:1

Filtration Range Number Link Update Network Topology Model
    [Documentation]    Tests the processing of link update requests when using a range-number filtration on NT model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    network-topology-model    link    network-topo:1
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:metric
    ${request}    Set Range Number Filter    ${request}    11    13
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <link-id>link:    3
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    #Filter a link out
    ${request}    Create Link    link:1:4    bgp:1    bgp:4    linkA    15
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:1/link/link:1:4
    ${resp}    Basic Request Get And Test    ${request}    network-topology:network-topology/topology/topo:1    <link-id>    2
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:3</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:2-1</link-ref>    1
    Should Not Contain    ${resp.content}    network-topology/topology/network-topo:1/link/link:1:4
    #Put the link back in
    ${request}    Create Link    link:1:4    bgp:1    bgp:4    linkA    12
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:1/link/link:1:4
    ${resp}    Basic Request Get And Test    ${request}    network-topology:network-topology/topology/topo:1    <link-id>    3
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:4</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:3</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/network-topo:1/link/link:1:2-1</link-ref>    1

Filtration Range Number Link Update Inventory Model
    [Documentation]    Tests the processing of link update requests when using a range-number filtration on Inventory model
    ${request}    Prepare Filtration Topology Request    ${FILTRATION_NT}    opendaylight-inventory-model    link    openflow-topo:3
    ${request}    Insert Filter    ${request}    ${FILTER_RANGE_NUMBER}    l3-unicast-igp-topology:igp-link-attributes/l3-unicast-igp-topology:metric
    ${request}    Set Range Number Filter    ${request}    14    15
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <link-id>link:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    ${request}    Create Link    link:11:12    of-node:11    of-node:12    linkB    14
    Basic Request Put    ${request}    network-topology:network-topology/topology/openflow-topo:3/link/link:11:12
    ${resp}    Basic Request Get And Test    ${request}    network-topology:network-topology/topology/topo:1    <link-id>    3
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:14:12</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:15:13</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:11:12</link-ref>    1
    ${request}    Create Link    link:11:12    of-node:11    of-node:12    linkB    13
    Basic Request Put    ${request}    network-topology:network-topology/topology/openflow-topo:3/link/link:11:12
    ${resp}    Basic Request Get And Test    ${request}    network-topology:network-topology/topology/topo:1    <link-id>    2
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:14:12</link-ref>    1
    Should Contain X Times    ${resp.content}    <link-ref>/network-topology/topology/openflow-topo:3/link/link:15:13</link-ref>    1

Unification Filtration Node Update Inside Network Topology model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    network-topology-model    node    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    network-topo:4
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain    ${resp.content}    <node-ref>bgp:    3
    ${request}    Create Isis Node    bgp:17    10    192.168.2.1
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:4/node/bgp:17
    ${resp}    Basic Request Get    network-topology:network-topology/topology/topo:1
    : FOR    ${index}    IN RANGE    17    21
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Validate Supporting Node Node-Ref Content    ${resp}    bgp:18    bgp:17    bgp:20

    ${request}    Create Isis Node    bgp:17    10    192.168.1.2
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:4/node/bgp:17
    ${resp}    Basic Request Get    network-topology:network-topology/topology/topo:1
    : FOR    ${index}    IN RANGE    18    21
    \    Should Contain X Times    ${resp.content}    <node-ref>bgp:${index}</node-ref>    1
    Validate Supporting Node Node-Ref Content    ${resp}    bgp:18    bgp:20

Unification Filtration Node Update Inside Inventory model
    ${request}    Prepare Unification Filtration Inside Topology Request    ${UNIFICATION_FILTRATION_NT_AGGREGATE_INSIDE}    opendaylight-inventory-model    node    flow-node-inventory:ip-address    openflow-topo:4
    ${request}    Insert Filter With ID    ${request}    ${FILTER_IPV4}    flow-node-inventory:ip-address    1
    ${request}    Insert Apply Filters    ${request}    1    1
    ${request}    Set IPV4 Filter    ${request}    192.168.2.1/24
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    2
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain    ${resp.content}    <node-ref>of-node:    4
    ${request}    Create Openflow Node    openflow:17    192.168.1.2
    Basic Request Put    ${request}    opendaylight-inventory:nodes/node/openflow:17
    ${resp}    Basic Request Get    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain    ${resp.content}    <node-ref>of-node:    3
    : FOR    ${index}    IN RANGE    18    21
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='of-node:19']/..
    ${node}    Element to String    ${node}
    Should Contain X Times    ${node}    <supporting-node>    2
    Should Contain    ${node}    <node-ref>of-node:19</node-ref>
    Should Contain    ${node}    <node-ref>of-node:20</node-ref>
    Should Not Contain    ${node}    <node-ref>of-node:17</node-ref>
    ${request}    Create Openflow Node    openflow:17    192.168.2.3
    Basic Request Put    ${request}    opendaylight-inventory:nodes/node/openflow:17
    ${resp}    Basic Request Get    network-topology:network-topology/topology/topo:1
    : FOR    ${index}    IN RANGE    17    21
    \    Should Contain X Times    ${resp.content}    <node-ref>of-node:${index}</node-ref>    1
    Validate Supporting Node Node-Ref Content    ${resp}    of-node:17    of-node:19    of-node:20

Link Computation Aggregation Inside Update NT
    [Documentation]    Test of link computation with unification type of aggregation inside on updated nodes from network-topology model 
    ${request}    Prepare Unification Inside Topology Request    ${UNIFICATION_NT_AGGREGATE_INSIDE}    network-topology-model    node    network-topo:6
    ${request}    Insert Target Field    ${request}    0    l3-unicast-igp-topology:igp-node-attributes/isis-topology:isis-node-attributes/isis-topology:ted/isis-topology:te-router-id-ipv4    0
    ${request}    Insert Link Computation Inside    ${request}    ${LINK_COMPUTATION_INSIDE}    n:network-topology-model    network-topo:6
    ${resp}    Send Basic Request And Test If Contain X Times    ${request}    network-topology:network-topology/topology/topo:1    <node-id>node:    4
    #Divide double nodes from overlay topology
    ${request}    Create Isis Node    bgp:29    router-id-ipv4=192.168.1.3
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:6/node/bgp:29
    ${resp}    Basic Request Get    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <link-id>    4
    ${node_26}    Get Supporting Node ID    ${resp}    bgp:26
    ${node_27}    Get Supporting Node ID    ${resp}    bgp:27
    ${node_28}    Get Supporting Node ID    ${resp}    bgp:28
    ${node_29}    Get Supporting Node ID    ${resp}    bgp:29
    ${node_30}    Get Supporting Node ID    ${resp}    bgp:30
    Validate Overlay Link Source And Destination    ${resp}    /network-topology/topology/network-topo:6/link/link:28:29    ${node_28}    ${node_29}
    Validate Overlay Link Source And Destination    ${resp}    /network-topology/topology/network-topo:6/link/link:26:28    ${node_26}    ${node_28}
    Validate Overlay Link Source And Destination    ${resp}    /network-topology/topology/network-topo:6/link/link:29:30-2    ${node_29}    ${node_30}
    Validate Overlay Link Source And Destination    ${resp}    /network-topology/topology/network-topo:6/link/link:29:30-1    ${node_29}    ${node_30}
    #Update link to node out of topology
    ${request}    Create Link    link:28:29    bgp:28    bgp:31    linkB    11
    Basic Request Put    ${request}    network-topology:network-topology/topology/network-topo:6/link/link:28:29
    ${resp}    Basic Request Get    network-topology:network-topology/topology/topo:1
    Should Contain    ${resp.content}    <topology-id>topo:1</topology-id>
    Should Contain X Times    ${resp.content}    <link-id>    3
    #Refresh node IDs
    ${node_26}    Get Supporting Node ID    ${resp}    bgp:26
    ${node_27}    Get Supporting Node ID    ${resp}    bgp:27
    ${node_28}    Get Supporting Node ID    ${resp}    bgp:28
    ${node_29}    Get Supporting Node ID    ${resp}    bgp:29
    ${node_30}    Get Supporting Node ID    ${resp}    bgp:30
    Should Not Contain    ${resp.content}    /network-topology/topology/network-topo:6/link/link:28:29
    Validate Overlay Link Source And Destination    ${resp}    /network-topology/topology/network-topo:6/link/link:26:28    ${node_26}    ${node_28}
    Validate Overlay Link Source And Destination    ${resp}    /network-topology/topology/network-topo:6/link/link:29:30-2    ${node_29}    ${node_30}
    Validate Overlay Link Source And Destination    ${resp}    /network-topology/topology/network-topo:6/link/link:29:30-1    ${node_29}    ${node_30}

*** Keywords ***
Get Supporting Node ID
    [Documentation]    Finds the supporting-node element containing the given node-ref and extracts its ID
    [Arguments]    ${resp}    ${node_ref_id}
    ${supporting_node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='${node_ref_id}']/..
    ${supp_node_id}    Get Element Text    ${supporting_node}    xpath=./node-id
    [Return]    ${supp_node_id}

Validate Supporting Node Node-Ref Content
    [Documentation]    Checks if the supporting-node element with specified node-ref contains node-refs from the given list
    [Arguments]    ${resp}    ${node_ref_id}    @{node_ref_list}
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='${node_ref_id}']/..
    ${node}    Element to String    ${node}
    :FOR    ${id}     IN      @{node_ref_list}
    \    Should Contain X Times    ${node}    <node-ref>${id}</node-ref>    1

Validate Supporting Node TP-Ref Content
    [Documentation]    Checks if the supporting-node element with specified node-ref contains node-refs from the given list
    [Arguments]    ${resp}    ${topology_id}    ${node_ref_id}    @{tp_ref_list}
    ${node}    Get Element    ${resp.content}    xpath=.//node/supporting-node[node-ref='${node_ref_id}']/..
    ${node}    Element to String    ${node}
    :FOR    ${id}     IN      @{tp_ref_list}
    \    Should Contain X Times    ${node}    /topology/${topology_id}/node/${node_ref_id}/termination-point/${id}</tp-ref>    1

Validate Overlay Link Source And Destination
    [Documentation]    Checks if the overlay link's source and destination specified by a supporting link ref matches given source and destination
    [Arguments]    ${resp}    ${link_ref}    ${expected_source}    ${expected_destination}
    ${link}    Get Element    ${resp.content}    xpath=.//link/supporting-link[link-ref='${link_ref}']/..
    ${link}    Element to String    ${link}
    ${link_source}    Get Element Text    ${link}    xpath=.//source-node
    ${link_destination}    Get Element Text    ${link}    xpath=.//dest-node
    Should Be Equal As Strings    ${link_source}    ${expected_source}
    Should Be Equal As Strings    ${link_destination}    ${expected_destination}