import Foundation
import Ignite

struct About: StaticPage {
  var title = "我"

  var workYear: Int {
    let currentYear = Calendar.current.component(.year, from: Date())
    return currentYear - 2017
  }

  var body: some HTML {
    Section {
      Group {
        Image("/images/avatar.png", description: "头像")
          .resizable()
          .frame(width: 180)
          .margin(.bottom, .medium)

        HStack(alignment: .bottom) {
          Text("Eden")
            .font(.title1)
            .fontWeight(.bold)

          Text("🎯 Focusing")
            .font(.xSmall)
            .foregroundStyle(.secondary)
            .padding(.bottom, 6)
        }
      }
      .padding(.bottom, .medium)

      Text(
        "Try to do Swift coding. | Feel confused about current life. | Want to do something useful."
      )
      .font(.lead)
      .padding(.bottom, .small)

      Text(
        markdown: """
          - A developer who has worked for \(workYear) years.
          - Learning Swift and Unity recently.
          - Currently working on some open-source projects.
          - Dream of making products that can be widely used.
          """
      )
      .font(.body)
      .frame(alignment: .topLeading)
      .padding(.bottom, .medium)

      Text(
        markdown: """
          You can find me on: [GitHub](https://github.com/LZhenHong), \
          [Twitter](https://twitter.com/yys_RySn), \
          [Mastodon](https://mastodon.social/@eden_yys).
          """
      )
      .font(.body)
      .padding(.bottom, .medium)

      Text("Thanks for reading!")
        .font(.body)
    }
    .padding(.all, .large)
  }
}
