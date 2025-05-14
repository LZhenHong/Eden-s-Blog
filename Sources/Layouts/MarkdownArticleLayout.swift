//
//  MarkdownArticleLayout.swift
//  blog
//
//  Created by Eden on 2025/5/9.
//

import Foundation
import Ignite

struct MarkdownArticleLayout: ArticlePage {
  var body: some HTML {
    Text(article.title)
      .font(.title1)

    if let tagLinks = article.tagLinks() {
      HStack(spacing: .xSmall) {
        ForEach(tagLinks) { link in
          link.font(.title3)
        }
      }
    }

    Text(article.text)
  }
}
