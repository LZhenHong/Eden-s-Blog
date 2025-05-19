import Foundation
import Ignite

struct SocialFooter: HTML {
  let icons = [
    Image(systemName: "github", description: "GitHub"),
    Image(systemName: "twitter", description: "Twitter"),
    Image(systemName: "mastodon", description: "Mastodon"),
  ]

  let urlStrings = [
    "https://github.com/lzhenhong",
    "https://twitter.com/yys_RySn",
    "https://mastodon.social/@eden_yys",
  ]

  var body: some HTML {
    VStack {
      HStack {
        ForEach(zip(icons, urlStrings)) { (icon, urlString) in
          Link(icon, target: urlString)
            .role(.secondary)
            .target(.blank)
            .relationship(.noOpener, .noReferrer)
        }
      }
    }
    .font(.title2)
    .padding(.vertical, .medium)
  }
}
