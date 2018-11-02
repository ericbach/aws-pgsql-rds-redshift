const { Pool } = require("pg");
const { S3 } = require("aws-sdk");

const pg_client_pool = new Pool({
    max: 1
});

const s3_client = new S3();

exports.handler = async (event) => {
    
    const client = await pg_client_pool.connect();

    let slot_name = process.env.SlotName;
    
    // Third parameter can limit the number of rows to return
    let result = await client.query(`SELECT * FROM pg_logical_slot_get_changes('${slot_name}', NULL, NULL);`);
    let changes = result.rows;
    if (changes.length > 0) {
        let output = JSON.stringify({ changes }, null, 2);

        // Format WAL logs into JSON
        let data = JSON.parse(output)['changes'];
        //console.log("Received: " + JSON.stringify(data));
        for (var i = 0; i < data.length; i++) 
        {
            let d = data[i];
            //console.log("Filtering: " + JSON.stringify(d));
            if (d['data'].startsWith("table public."))
            {
                let processedData = d['data'];
                console.log("Cleansing: " + processedData);

                // Remove static text
                processedData = processedData.replace("table public.", "")
                processedData = processedData.replace("INSERT: ", "{")
                // Change single quotes (') to quotes (")
                processedData = processedData.replace(/\'/gi, "\"");
                // Remove type text
                processedData = processedData.replace(/\[bigint\]:/gi, ":\"")
                processedData = processedData.replace(/\[integer\]:/gi, ":\"")
                processedData = processedData.replace(/\[numeric\]:/gi, ":\"")
                processedData = processedData.replace(/\[text\]/gi, "")
                processedData = processedData.replace(/\[timestamp without time zone\]/gi, "")
                // Add quotes around each value
                processedData = processedData.replace(/\s\"/gi, "\" \"");
                processedData = processedData.replace(/\"\"/gi, "\"");
                processedData = processedData.replace(/\"\s\"/gi, "\", \"");
                processedData = processedData.replace(/null\"/gi, "null");
                // Add ending bracket
                processedData = processedData + "}";
                
                // Get table name
                let tableName = processedData.substring(0, processedData.indexOf(":") - 1);
                // Remove table name
                processedData = processedData.replace(tableName + "\":", "");

                // TODO Only lowercase the field names and not the values
                output = processedData.toLowerCase();
                console.log("Cleansed: " + JSON.stringify(output));
            }

            let date = Date.now();
            let key = process.env.PGDATABASE + "_"  + date;
            try {
                await s3_client.upload({ Bucket: process.env.BUCKETNAME, Key: `${key}.json`, Body: output }).promise();
            }
            catch(e) {
                console.log(`s3 upload error: ${JSON.stringify(e)}`);
            }
        }
    }

    client.release();
};