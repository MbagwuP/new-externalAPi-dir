# External API

To run:

    bundle exec rackup -p 9292

For working on API docs CSS:

    sass --watch public/api-docs/css

Make changes in the SCSS files, and the changes will be compiled into the CSS files.

# ENV FILE
There is a dependency file that you will need to run locally. We have included the `dotenv` gem. You will need a `.env` file in the root of this project with the following environment variables defined.

```
export CONFIG_CIRCULAB_MIRTH_KEY="REPLACE_WITH_SECRET"
export CONFIG_CIRCULAB_MIRTH_ID="REPLACE_WITH_SECRET"
export CONFIG_CIRCULAB_BUSINESS_ENTITY_ID="1331"
export CONFIG_CIRCULAB_PROVIDER_ID="4623"
export CONFIG_CIRCULAB_PROVIDER_NPI="1669471090"
export CONFIG_CLINICAL_API_URL="CLINICAL_API_ENDPOINT"
```