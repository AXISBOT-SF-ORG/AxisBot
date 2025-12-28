export class MarkdownParser {
  static async parseMarkdown(markdown, markedLibUrl) {
    console.log("[MarkdownParser] Starting parseMarkdown");

    if (!markdown) {
      console.warn("[MarkdownParser] Empty markdown provided");
      return "";
    }

    try {
      // Load marked library from static resource
      console.log("[MarkdownParser] Loading marked from static resource...");
      console.log("[MarkdownParser] Marked library URL:", markedLibUrl);

      if (!window.marked) {
        console.log(
          "[MarkdownParser] window.marked not found, loading from static resource..."
        );
        await this.loadMarkedFromStaticResource(markedLibUrl);
      } else {
        console.log("[MarkdownParser] window.marked already available");
      }

      // Configure marked options
      console.log("[MarkdownParser] Configuring marked options...");
      window.marked.setOptions({
        breaks: true,
        gfm: true,
        pedantic: false
      });

      // Convert markdown to HTML
      console.log("[MarkdownParser] Converting markdown to HTML...");
      const html = window.marked.parse(markdown);

      console.log("[MarkdownParser] Conversion successful");
      console.log("[MarkdownParser] HTML output length:", html.length);

      return html;
    } catch (error) {
      console.error("[MarkdownParser] Error parsing markdown:", error);
      console.error("[MarkdownParser] Stack trace:", error.stack);
      return markdown;
    }
  }

  static loadMarkedFromStaticResource(markedLibUrl) {
    console.log("[MarkdownParser] Creating script tag for marked library");

    return new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = markedLibUrl;
      script.type = "text/javascript";

      console.log("[MarkdownParser] Script src set to:", markedLibUrl);

      script.onload = () => {
        console.log("[MarkdownParser] Script loaded successfully");
        console.log(
          "[MarkdownParser] window.marked available:",
          !!window.marked
        );

        if (window.marked) {
          console.log(
            "[MarkdownParser] marked.parse function available:",
            typeof window.marked.parse
          );
          resolve();
        } else {
          console.error(
            "[MarkdownParser] marked library loaded but window.marked is undefined"
          );
          reject(
            new Error(
              "marked library loaded but not available on window object"
            )
          );
        }
      };

      script.onerror = (error) => {
        console.error(
          "[MarkdownParser] Failed to load marked library from static resource"
        );
        console.error("[MarkdownParser] Error details:", error);
        reject(new Error("Failed to load marked library from static resource"));
      };

      script.onabort = () => {
        console.error("[MarkdownParser] Script loading was aborted");
        reject(new Error("Script loading was aborted"));
      };

      console.log("[MarkdownParser] Appending script to document head...");
      document.head.appendChild(script);
      console.log("[MarkdownParser] Script appended to head");
    });
  }
}
