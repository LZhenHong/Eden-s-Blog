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
  var name = "Eden's Blog"
  var titleSuffix = " – Just Someone"
  var url = URL(static: "https://www.example.com")
  var builtInIconsEnabled = true

  var author = "Eden"

  var homePage = Home()
  var layout = MainLayout()

  var articlePages: [any ArticlePage] {
    CustomArticleLayout()
  }
}
