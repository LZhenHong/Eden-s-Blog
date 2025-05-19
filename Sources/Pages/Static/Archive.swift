import Foundation
import Ignite

struct Archive: StaticPage {
  @Environment(\.articles) var articles

  var title = "归档"

  var yearArchives: [Int: [Article]] {
    Dictionary(grouping: articles.all, by: { $0.date.year })
  }

  var years: [Int] {
    yearArchives.keys.sorted(by: >)
  }

  var body: some HTML {
    Text(title)
      .font(.title1)
      .padding()

    ForEach(years) { year in
      YearArchive(year: year, archives: yearArchives[year] ?? [])
        .padding(.bottom)
    }
  }
}

private struct YearArchive: HTML {
  var year: Int
  var archives: [Article]

  var sortedArchives: [Article] {
    archives.sorted(by: { $0.date > $1.date })
  }

  var body: some HTML {
    Text("\(year)")
      .font(.title2)
      .fontWeight(.bold)
      .padding()

    List(sortedArchives) { article in
      Link(article.archiveTitle, target: article)
        .font(.body)
        .padding()
    }
  }
}

extension Article {
  var archiveTitle: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let dateString = formatter.string(from: date)
    return "\(dateString) · \(title)"
  }
}
