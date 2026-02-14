import Foundation
import SwiftSoup

struct HTMLFormatter {
    static func formatArticle(item: Item, isDarkMode: Bool) -> String {
        do {
            // Parse the article HTML
            let document = try SwiftSoup.parse(item.html)

            // Create CSS
            let css = generateCSS(isDarkMode: isDarkMode)
            let styleElement = try document.createElement("style")
            try styleElement.attr("type", "text/css")
            try styleElement.text(css)

            // Create title header
            let titleDiv = try document.createElement("div")
            try titleDiv.attr("style", "text-align: center;")

            let h1 = try document.createElement("h1")
            try h1.text(item.title)
            try titleDiv.appendChild(h1)

            // Add author if available
            if let author = item.author, !author.isEmpty {
                let authorDiv = try document.createElement("div")
                try authorDiv.attr("style", "color: gray")
                try authorDiv.text(author)
                try titleDiv.appendChild(authorDiv)
            }

            // Add date
            let dateDiv = try document.createElement("div")
            try dateDiv.attr("style", "color: gray")
            let dateString = formatDate(timestamp: item.createdOnTime)
            try dateDiv.text(dateString)
            try titleDiv.appendChild(dateDiv)

            // Create body wrapper with max-width
            let bodyWrapper = try document.createElement("div")
            try bodyWrapper.attr("style", "max-width: 1000px; margin: 0 auto;")

            // Move existing body content into wrapper
            if let body = document.body() {
                let bodyHTML = try body.html()
                try bodyWrapper.html(bodyHTML)

                // Clear body and add our formatted content
                try body.empty()
                try body.appendChild(styleElement)
                try body.appendChild(titleDiv)
                try body.appendChild(bodyWrapper)
            }

            return try document.html()
        } catch {
            print("HTML formatting error: \(error)")
            // Fallback to simple HTML if parsing fails
            return """
            <html>
            <head>
                <style>\(generateCSS(isDarkMode: isDarkMode))</style>
            </head>
            <body>
                <div style="text-align: center;">
                    <h1>\(item.title)</h1>
                    \(item.author != nil ? "<div style=\"color: gray\">\(item.author!)</div>" : "")
                    <div style="color: gray">\(formatDate(timestamp: item.createdOnTime))</div>
                </div>
                <div style="max-width: 1000px; margin: 0 auto;">
                    \(item.html)
                </div>
            </body>
            </html>
            """
        }
    }

    private static func generateCSS(isDarkMode: Bool) -> String {
        var css = """
        body {
            font-size: 1.2em;
        }
        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 0 auto;
        }
        """

        if isDarkMode {
            css += """

            body {
                color: #eee;
                background-color: #333;
            }
            a:link {
                color: #37abc8;
            }
            """
        }

        return css
    }

    private static func formatDate(timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
