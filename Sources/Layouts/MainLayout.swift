import Foundation
import Ignite

struct MainLayout: Layout {
  var body: some Document {
    Body {
      Navigator()
        .padding(.bottom, 80)
      content
      SocialFooter()
    }
  }
}
