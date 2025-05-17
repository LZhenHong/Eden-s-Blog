import Foundation
import Ignite

struct About: StaticPage {
  var title = "关于"

  var body: some HTML {
    Text("关于")
      .font(.title1)
      .padding()
    Text("这里是关于我的描述，您可以在此处添加个人简介或联系方式。")
      .font(.body)
      .padding()
  }
}
