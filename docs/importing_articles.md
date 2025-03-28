# Handling Article Imports

## Article mentions

### Prerequisites
Before tackling article mentions, you need to understand the [rich_text](./supported_types.md#rich_text) type.

### What kind of mentions are supported?
We support mentions to artifacts and articles. An inline attachment must be mapped to an artifact. A link to another article must be mapped to an article.

### How to handle mentions?

#### Inline attachments
If an inline attachment is hosted in the source system, it must be created as an artifact in DevRev. The same link cannot be used as the attachment will be deleted in the source system when our customers deactivate the account. However, creating an artifact is not enough. The artifact must linked in the appropriate place in the article content. 

##### HTML
```
<img src="don:core:dvrv-us-1:devo/0:artifact/1" alt="Alt Text"/>
```

##### Markdown
```
![Alt Text](don:core:dvrv-us-1:devo/0:artifact/1)
```

##### Example
Let's say the content of your external system looks like this:
```
<p>This is an article with one image.</p>
<p><img src="https://devrev.zendesk.com/hc/article_attachments/29908544740244" alt="download.jpeg"></p>
```

The content in DevRev should look like this:
```
<p>This is an article with one image.</p>
<p><img src="don:core:dvrv-us-1:devo/0:artifact/1" alt="download.jpeg"></p>
```

`don:core:dvrv-us-1:devo/0:artifact/1` is the ID of the artifact created in DevRev corresponding to the attachment with ID `29908544740244` in the external source system.
To achieve this, you need to transform the content of the article to this:
```
[ 
    "<p>This is an article with one image.</p><p><img src=\"",
    {
        "ref_type": "artifact",
        "id": "29908544740244",
        "fallback_record_name": "<fallback link>"
    },
    "\" alt=\"download.jpeg\"></p>" 
]
```
The ref_type should be set to artifact and the ID should be the ID of the attachment in the external source system. The platform simply replaces the mention block with the ID of the corresponding artifact. The resolved value is not wrapped in double quotes.

#### Links to other articles
If there is a link to another article in the content of the article, you need to create a mention to the article. The link must be to an article that was either created in previous syncs or will be created in the current sync. At the extractor stage, it is impossible to predict the ID of the article that will be created in DevRev. So, this must be handled by the platform. This feature is only available for HTML format. However, since Markdown can contain HTML, you can use the same approach for Markdown as well.

##### HTML
```
<a data-article-id="don:core:dvrv-us-1:devo/0:article/10" href="/ART-10" target="_self">Contact our Support Team</a>
```

##### Example
Let's say the content of your external system looks like this:
```
<p>You can create an account and log-in <a href="https://devrev.zendesk.com/hc/en-us/articles/360059607772" target="_self">only</a> with the company email.
```

The content in DevRev should look like this:
```
<p>You can create an account and log-in <a data-article-id="don:core:dvrv-us-1:devo/0:article/10" href="/ART-10" target="_self">only</a> with the company email.
```

`don:core:dvrv-us-1:devo/0:article/10` is the ID of the article created in DevRev corresponding to the article with ID `360059607772` in the external source system.
To achieve this, you need to transform the content of the article to this:
```
[
    "You can create an account and log-in <a data-article-id=\"",
    {
        "ref_type": "article",
        "id": "360059607772",
        "fallback_record_name": "<fallback article ID>"
    },
    "\" target=\"_self\"> only</a> with the company email."
]
```
The ref_type should be set to the item type in the external system that is being mapped to articles. For example, if you're importing documents from the external system as articles, the `ref_type` should be set to documents. The ID should be the ID of the item in the external source system. The platform replaces the mention block with the ID of the corresponding article in DevRev as well as adds the href attribute with the appropriate value.

## Managing Permissions

You can manage permissions in the `shared_with` field. Permissions can reference users, groups and [platform groups](./platform_groups.md).
