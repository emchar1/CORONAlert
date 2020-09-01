# CORONAlert
Obtain the latest COVID-19 information based on your current location.

Since the App Store is not accepting apps created by individuals surrounding the COVID-19 pandemic, I've decided to upload my project here in hopes it can benefit anyone interested in the data. The data comes from COVID-19 Statistics API on rapidapi.com, which itself is based on public data by Johns Hopkins CSSE.

Once you've cloned the project, you'll need to create an account on https://rapidapi.com to get your own API key. Then add the following constants to your project:

let rapidAPIKey = "<your_api_key>"
let productID = "<your_product_id>"

where <your_api_key> is your personal API key as a string value.
where <your_product_id> is the product id of your app for in-app purchases in App Store Connect.
