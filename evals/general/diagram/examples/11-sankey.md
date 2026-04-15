### Website Traffic Acquisition & Conversion Funnel

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%
sankey-beta

"Organic Search","Blog and Content",1637
"Organic Search","Product Pages",1348
"Organic Search","Landing Pages",1252
"Organic Search","Homepage",963
"Google Ads","Blog and Content",661
"Google Ads","Product Pages",544
"Google Ads","Landing Pages",506
"Google Ads","Homepage",389
"Social Media","Blog and Content",504
"Social Media","Product Pages",415
"Social Media","Landing Pages",385
"Social Media","Homepage",296
"Direct Bookmarks","Blog and Content",331
"Direct Bookmarks","Product Pages",272
"Direct Bookmarks","Landing Pages",253
"Direct Bookmarks","Homepage",194
"Email Campaigns","Blog and Content",267
"Email Campaigns","Product Pages",221
"Email Campaigns","Landing Pages",204
"Email Campaigns","Homepage",158
"Blog and Content","Trial Signup",290
"Blog and Content","Newsletter Subscription",425
"Blog and Content","Demo Request",120
"Blog and Content","Bounce",2565
"Product Pages","Trial Signup",238
"Product Pages","Newsletter Subscription",350
"Product Pages","Demo Request",99
"Product Pages","Bounce",2113
"Landing Pages","Trial Signup",222
"Landing Pages","Newsletter Subscription",325
"Landing Pages","Demo Request",92
"Landing Pages","Bounce",1961
"Homepage","Trial Signup",170
"Homepage","Newsletter Subscription",250
"Homepage","Demo Request",69
"Homepage","Bounce",1511
```

Three-layer Sankey showing website traffic flow: 5 acquisition sources distribute across 4 landing destination types, then flow to 4 outcomes. Total volume 10,800 visits. Bounce dominates at 8,150 (75.5%). `sankey-beta` has no `classDef` support — theme init block handles all colors.

> **Note:** `sankey-beta` requires Mermaid >= 10.3.0. Renderers on 10.2.x will show a syntax error.
