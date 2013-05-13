Neo_Concept
-----------

Sample import for ConceptNet5 dataset as a regular graph.

Pre-Requisites
--------------

To regenerate: Download and compile the [Neo4j Batch Importer](https://github.com/jexp/batch-import) and place it in a directory as the same level as this one. 

Or Download the Neo4j [graph.db](https://dl.dropboxusercontent.com/u/57740873/conceptnet.graph.db.zip) from dropbox and place in your Neo4j data directory.

How-To From Scratch
-------------------

    bundle
    rake neo4j:install
    rake neo4j:create
    rake neo4j:load
    rake neo4j:start_no_wait

How-To Download
-------------------

    bundle
    rake neo4j:install
    cd neo4j/data
    wget https://dl.dropboxusercontent.com/u/57740873/conceptnet.graph.db.zip
    unzip conceptnet.graph.db.zip
    cd ../..    
    rake neo4j:start_no_wait


Goto localhost:7474 to see graph.


