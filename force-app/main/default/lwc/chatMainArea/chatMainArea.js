import { LightningElement, track } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import MARKED_JS from "@salesforce/resourceUrl/markedjs";

export default class ChatMainArea extends LightningElement {
  @track userInput = "";
  @track selectedRelease = "winter26";
  @track isLoading = false;
  displaySettings = false;
  displayLogs = false;
  maxTokens = 512;
  queryCount = 0;

  markedLoaded = false;

  handleTokenChange(event) {
    this.maxTokens = event.target.value;
  }

  handleDisplayLogsChange() {
    this.displayLogs = !this.displayLogs;
  }

  handleClose() {
    this.displaySettings = !this.displaySettings;
  }

  @track messages = [
    {
      id: 1,
      text: "Hi 👋 Ask me anything about Salesforce release notes.",
      htmlContent: null,
      cssClass: "message bot",
      hasLogs: false
    }
  ];

  renderedCallback() {
    console.log("[ChatMainArea] renderedCallback called");
    console.log("[ChatMainArea] Total messages:", this.messages.length);
    // const container = this.template.querySelector(".chat-container");
    // container.style.height = `${window.innerHeight - 34}px`;
    // Render markdown content
    this.messages.forEach((msg) => {
      console.log(
        "[ChatMainArea] Processing message ID:",
        msg.id,
        "Has HTML:",
        !!msg.htmlContent
      );

      if (msg.htmlContent) {
        const bubble = this.template.querySelector(`[data-id="${msg.id}"]`);
        console.log(
          "[ChatMainArea] Found bubble element for ID",
          msg.id,
          ":",
          !!bubble
        );

        if (bubble) {
          console.log(
            "[ChatMainArea] Setting innerHTML for message ID:",
            msg.id
          );
          console.log(
            "[ChatMainArea] HTML content length:",
            msg.htmlContent.length
          );
          bubble.innerHTML = msg.htmlContent;
          console.log("[ChatMainArea] innerHTML set successfully");
        }
      }
    });

    // Position settings dialog
    // if (this.displaySettings) {
    //   console.log("[ChatMainArea] Positioning settings dialog");
    //   const gear = this.template.querySelector(".gear-button");
    //   const settings = this.template.querySelector(".settings");

    //   console.log("[ChatMainArea] Gear element found:", !!gear);
    //   console.log("[ChatMainArea] Settings element found:", !!settings);

    //   if (gear && settings) {
    //     const gearBoundaries = gear.getBoundingClientRect();
    //     const top = Math.round(gearBoundaries.bottom) + 4;
    //     const right = Math.round(gearBoundaries.right);

    //     console.log("[ChatMainArea] Positioning: top=", top, "right=", right);

    //     settings.style.top = `${top}px`;
    //     settings.style.right = `${window.innerWidth - right}px`;
    //     settings.style.display = "block";
    //   }
    // }
  }

  connectedCallback() {
    if (this.markedLoaded) {
      return;
    }

    loadScript(this, MARKED_JS)
      .then(() => {
        this.markedLoaded = true;
        console.log("[ChatMainArea] marked.js loaded successfully");
      })
      .catch((error) => {
        console.error("[ChatMainArea] Failed to load marked.js", error);
      });
  }

  releaseOptions = [
    { label: "Winter 26", value: "winter26", isActive: true },
    { label: "Spring 25", value: "spring25", isActive: false },
    { label: "Summer 25", value: "summer25", isActive: false }
  ];

  handleInputChange(event) {
    this.userInput = event.target.value;
  }

  handleReleaseChange(event) {
    this.selectedRelease = event.detail.value;
  }

  handleKeyPress(event) {
    if (event.key === "Enter") {
      this.handleSend();
    }
  }

  async handleSend() {
    console.log("[ChatMainArea] handleSend called");
    console.log("[ChatMainArea] User input:", this.userInput);

    if (!this.userInput.trim()) {
      console.warn("[ChatMainArea] Empty user input, returning");
      return;
    }

    this.isLoading = true;
    console.log("[ChatMainArea] Setting isLoading to true");

    this.messages = [
      ...this.messages,
      {
        id: Date.now(),
        text: this.userInput,
        htmlContent: null,
        cssClass: "message user",
        hasLogs: false
      }
    ];

    if (this.selectedRelease !== "winter26") {
      this.messages = [
        ...this.messages,
        {
          id: Date.now(),
          text: "Selected Release is not available. Please select a different one.",
          htmlContent: null,
          cssClass: "message bot",
          hasLogs: false
        }
      ];
      this.isLoading = false;
      this.userInput = "";
      return;
    }

    if (this.queryCount >= 3) {
      this.messages = [
        ...this.messages,
        {
          id: Date.now(),
          text: "Query limit Exceeded!",
          htmlContent: null,
          cssClass: "message bot",
          hasLogs: false
        }
      ];
      this.isLoading = false;
      this.userInput = "";
      return;
    }

    const requestPayload = {
      question: this.userInput,
      release: this.selectedRelease,
      config: {
        maxTokens: this.maxTokens,
        temperature: 0.5
      },
      needInsights: this.displayLogs
    };

    console.log(
      "[ChatMainArea] Request payload:",
      JSON.stringify(requestPayload)
    );
    this.userInput = "";

    try {
      console.log("[ChatMainArea] Making fetch request to Lambda...");
      const callLambda = await fetch(
        "https://qw66tdlhjc4guug3zje7h5ptry0ihmys.lambda-url.ap-south-1.on.aws/",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify(requestPayload)
        }
      );
      this.queryCount++;

      console.log("[ChatMainArea] Fetch response status:", callLambda.status);

      if (!callLambda.ok) {
        console.error(
          "[ChatMainArea] Lambda returned error status:",
          callLambda.status
        );
        this.isLoading = false;
        this.messages = [
          ...this.messages,
          {
            id: Date.now() + 1,
            text: `Error: ${callLambda.status} ${callLambda.statusText}`,
            htmlContent: null,
            cssClass: "message bot",
            hasLogs: false
          }
        ];
        return;
      }

      const response = await callLambda.json();
      console.log("[ChatMainArea] Lambda response:", response);
      console.log("[ChatMainArea] Response answer:", response.answer);

      // Parse markdown to HTML using marked library from static resource
      console.log("[ChatMainArea] Calling marked.js to parse markdown...");
      const markdownText = response?.answer || "";
      const htmlContent =
        this.markedLoaded && window.marked
          ? window.marked.parse(markdownText)
          : markdownText;
      console.log(
        "[ChatMainArea] HTML content generated, length:",
        htmlContent.length
      );

      this.isLoading = false;
      this.messages = [
        ...this.messages,
        {
          id: Date.now() + 1,
          text:
            response?.answer || "Unable to generate answer. Please try again.",
          htmlContent: htmlContent,
          cssClass: "message bot",
          hasLogs: response?.insights ? true : false,
          logInfo: {
            reasoning: response?.reasoning,
            timings: {
              faissLoadMs: response?.insights?.timings?.faissLoadMs || 0,
              llmInferenceMs: response?.insights?.timings?.llmInferenceMs || 0
            },
            retrieval: {
              documentsReturned:
                response?.insights?.retrieval?.documentsReturned || 0,
              sources: response?.insights?.retrieval?.sources || []
            }
          }
        }
      ];
      console.log("[ChatMainArea] Message added to messages array");
    } catch (error) {
      console.error("[ChatMainArea] Error in handleSend:", error);
      console.error("[ChatMainArea] Error message:", error.message);
      console.error("[ChatMainArea] Error stack:", error.stack);

      this.isLoading = false;
      this.messages = [
        ...this.messages,
        {
          id: Date.now() + 1,
          text: `Error: ${error.message}`,
          htmlContent: null,
          cssClass: "message bot",
          hasLogs: false
        }
      ];
    }
  }

  handleSettings() {
    this.displaySettings = !this.displaySettings;
  }
}
