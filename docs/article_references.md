# Handling Article References


## Prerequisites
Before tackling article references, you need to understand the [rich_text](./supported_types.md#rich_text) type.

## What kind of references are supported?
We support references to artifacts and articles. An inline attachment must be mapped to an artifact. A link to another article must be mapped to an article.

## How to handle references?

### Inline attachments
If an inline attachment is hosted in the source system, it must be created as an artifact in DevRev. The same link cannot be used as the attachment will be deleted in the source system when our customers deactivate the account. However, creating an artifact is not enough. The artifact must linked in the appropriate place in the article content. 

#### HTML
```
<img src="don:core:dvrv-us-1:devo/0:artifact/1" alt="Alt Text"/>
```

#### Markdown
```
![Alt Text](don:core:dvrv-us-1:devo/0:artifact/1)
```

#### Example
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

`don:core:dvrv-us-1:devo/0:artifact/1` is the ID of the artifact created in DevRev.
To achieve this, you need to transform the content of the article to this:
```json
{
    "type": "rich_text",
    "content": [
        "<p>This is an article with one image.</p><p><img src=\"",
        {
            "ref_type": "artifact",
            "id": "29908544740244",
            "fallback_record_name": "<fallback link>"
        },
        "\" alt=\"download.jpeg\"></p>"
    ]
}
```
The platform simply replaces the reference block with the ID of the artifact. The resolved value in not wrapped in double quotes. 

### Links to other articles
If an article links to another article, you need to create a reference to the article in the content of the article. This is important because at the extractor stage, it is impossible to predict the ID of the article that will be created in DevRev. This feature is only available for HTML format. However, since Markdown can contain HTML, you can use the same approach for Markdown as well.

#### HTML
```
<a data-article-id="don:core:dvrv-us-1:devo/0:article/10" href="/ART-10" target="_self">Contact our Support Team</a>
```

#### Example
Let's say the content of your external system looks like this:
```
<p>You can create an account and log-in <a href="https://devrev.zendesk.com/hc/en-us/articles/360059607772" target="_self">only</a> with the company email.
```

The content in DevRev should look like this:
```
<p>You can create an account and log-in <a data-article-id="don:core:dvrv-us-1:devo/0:article/10" href="/ART-10" target="_self">only</a> with the company email.
```

`don:core:dvrv-us-1:devo/0:article/10` is the ID of the article created in DevRev.
To achieve this, you need to transform the content of the article to this:
```json
{
    "type": "rich_text",
    "content": [
        "You can create an account and log-in <a data-article-id=\"",
        {
            "ref_type": "article",
            "id": "360059607772",
            "fallback_record_name": "<fallback article ID>"
        },
        "\" target=\"_self\"> only</a> with the company email."
    ]
}
```

The platform replaces the reference block with the ID of the article as well as adds the href attribute with the appropriate value.