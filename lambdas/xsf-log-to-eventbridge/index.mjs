import {
  EventBridgeClient,
  PutEventsCommand,
} from "@aws-sdk/client-eventbridge";
import zlib from "node:zlib";

const eventbridge = new EventBridgeClient();
const logLevel = process.env.LOG_LEVEL || "INFO";
const debug = logLevel === "DEBUG";

export const handler = async (event) => {
  let logData;
  try {
    // CloudWatch Logs data comes base64 encoded and gzipped
    const payload = Buffer.from(event.awslogs.data, "base64");
    const decompressed = zlib.gunzipSync(payload);
    logData = JSON.parse(decompressed);
  } catch (error) {
    console.error("Failed to process CloudWatch Logs data:", error);
    throw error;
  }

  // Extract log events
  const logEvents = logData.logEvents;

  // Transform each log event into EventBridge entry
  const entries = logEvents
    .map((logEvent) => {
      // Parse the log message as JSON
      let stepFunctionEvent;
      try {
        stepFunctionEvent = JSON.parse(logEvent.message);
      } catch (error) {
        console.error("Failed to parse log event message:", error);
        // Skip this event if parsing fails
        return null;
      }

      return {
        Source: "7π.states",
        DetailType: "Express Step Functions Execution Status Change",
        Detail: JSON.stringify(stepFunctionEvent),
        EventBusName: "default",
      };
    })
    .filter((entry) => entry !== null);

  // Send events to EventBridge (in batches of 10 as per AWS limits)
  for (let i = 0; i < entries.length; i += 10) {
    const batch = entries.slice(i, i + 10);
    const command = new PutEventsCommand({
      Entries: batch,
    });

    const response = await eventbridge.send(command).catch((error) => {
      console.error("Failed to send events to EventBridge:", error);
      throw error;
    });

    if (response.FailedEntryCount > 0) {
      const failedEntries = response.Entries.filter((entry) => entry.ErrorCode);
      console.error("Some events failed to be sent:", failedEntries);

      // Log each failed entry individually if debug is enabled
      if (debug) {
        failedEntries.forEach((failedEntry) => {
          const entryIndex = response.Entries.indexOf(failedEntry);
          console.error(
            `Failed to send event ${i + entryIndex + 1}:`,
            `Error: ${failedEntry.ErrorCode} - ${failedEntry.ErrorMessage}`
          );
        });
      }

      throw new Error(
        `Failed to send ${response.FailedEntryCount} events to EventBridge`
      );
    }

    // Log successful entries if debug is enabled
    if (debug) {
      entries.forEach((entry, index) => {
        console.debug(
          `Successfully sent event ${index + 1}:`,
          JSON.stringify(entry)
        );
      });
    }
  }

  const result = {
    statusCode: 200,
    body: `Successfully processed ${entries.length} events`,
  };
  console.log(result.body);
};
