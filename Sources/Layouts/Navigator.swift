import Foundation
import Ignite

/// 网站导航组件，包含首页、归档、书籍、关于
struct Navigator: HTML {
  var body: some HTML {
    NavigationBar {
      Link("归档", target: Archive())
      Dropdown {
        Link("Cocos Creator 进阶", target: AdvancedCocosCreator())
      } title: {
        Span("书籍")
          .foregroundStyle(.white)
      }
      Link("关于", target: About())
    } logo: {
      Link(target: "/") {
        Image("/images/favicon.jpg", description: "Avatar")
          .resizable()
          .frame(width: 32, height: 32)
          .cornerRadius(10)
          .margin(.trailing, 10)
        Span("Eden's Blog")
          .fontWeight(.bold)
      }
      .foregroundStyle(.white)
      .font(.title3)
    }
    .navigationBarStyle(.automatic)
    .navigationItemAlignment(.trailing)
    .background(.firebrick)
    .position(.fixedTop)
  }
}
