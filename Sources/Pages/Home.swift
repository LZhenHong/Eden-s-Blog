import Foundation
import Ignite

struct Home: StaticPage {
  @Environment(\.articles) var articles
  var title = "Home"

  var body: some HTML {
    List {
      ForEach(articles.all) { article in
        Link(article)
      }
    }
  }
}
