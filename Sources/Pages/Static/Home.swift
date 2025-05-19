import Foundation
import Ignite

struct Home: StaticPage {
  @Environment(\.articles) var articles
  var title = "博客"

  var body: some HTML {
    Grid(articles.all, alignment: .top) { article in
      ArticlePreview(for: article)
        .width(3)
        .margin(.bottom)
    }
  }
}
