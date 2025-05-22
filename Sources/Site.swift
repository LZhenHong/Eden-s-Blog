import Foundation
import Ignite

@main
struct Website {
  static func main() async {
    var site = EdenBlog()
    do {
      try await site.publish()
    } catch {
      print(error.localizedDescription)
    }
  }
}

struct EdenBlog: Site {
  var name: String = .title
  var titleSuffix = " - Just Someone"
  var url = URL(static: "https://lzhenhong.github.io")
  var builtInIconsEnabled = true

  var author: String = .author
  var favicon = URL(string: .favicon)
  var language: Language = .chineseSimplified

  var syntaxHighlighterConfiguration: SyntaxHighlighterConfiguration = .init(languages: [
    .swift, .objectiveC, .c, .cSharp, .python,
  ])
  var useDefaultBootstrapURLs: BootstrapOptions { .remoteBootstrap }

  var homePage = Home()
  var layout = MainLayout()

  var staticPages: [any StaticPage] {
    Archive()
    About()
    AdvancedCocosCreator()
  }

  var articlePages: [any ArticlePage] {
    MarkdownArticleLayout()
  }
}
