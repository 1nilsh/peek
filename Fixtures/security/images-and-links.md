# Images and links

1. Image from the parent folder (needs the read-only file exception). Expected: teal "Peek fixture" image.

   ![parent folder](../samples/sample.png)

2. Remote Markdown image. Expected: dashed "remote" placeholder (unless "Load remote images" is on).

   ![remote](https://www.apple.com/favicon.ico)

3. Unsafe link target. Expected: "click me" is not a link.

   [click me](javascript:alert(1))

4. Bare URL. Expected: clickable link without the trailing period: https://example.com/path?x=1.
