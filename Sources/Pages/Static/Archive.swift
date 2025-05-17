import Foundation
import Ignite

struct Archive: StaticPage {
  @Environment(\.articles) var articles
  var title = "归档"

  var body: some HTML {
    Text("归档")
      .font(.title1)
      .padding()

    List {
      ForEach(articles.all) { article in
        Link(article)
      }
    }
  }
}
