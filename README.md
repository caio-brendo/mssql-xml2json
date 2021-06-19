<p align="center">
    <h1 align="center">mssql-xml2json</h1>
    <br>
</p>

mssql-xml2json is a script that converts a string XML for JSON format in Microsoft SQL Server 2008 that no has JSON support native

DIRECTORY STRUCTURE
-------------------

      src/             contains source code


REQUIREMENTS
------------

The minimum requirement is a server Microsoft SQL Server 2008 


INSTALLATION
------------

You can then install running the content of file install.sql in your mssql.

## RELEASE CHANGES

> NOTE: Refer the [CHANGE LOG](https://github.com/caio-brendo/mssql-xml2json/blob/master/CHANGE.md) for details on changes to various releases.

Enhancements with release v1.0.0:

- Converting a string XML to JSON format

USAGE
------------

### The XML

```xml
<movies>
    <movie>
        <title>Harry Potter and the Prisoner of Azkaban</title>
        <release>2004</release>
        <stars>
            <name>Daniel Radcliffe</name>
            <character>Harry Potter</character>
        </stars>
        <stars>
            <name>Emma Watson</name>
            <character>Hermione Granger</character>
        </stars>
        <stars>
            <name>Rupert Grint</name>
            <character>Ronald Weasley</character>
        </stars>
        <genre>Adventure</genre>
        <genre>Family</genre>
        <genre>Fantasy</genre>
    </movie>
    <movie>
        <title>Dragon Ball Super: Broly</title>
        <release>2018</release>
        <stars>
            <name>D Masako Nozawa (Voice)</name>
            <character>Son Goku</character>
        </stars>
        <stars>
            <name>Aya Hisakawa (Voice)</name>
            <character>Bulma</character>
        </stars>
        <stars>
            <name>Ryô Horikawa (Voice)</name>
            <character>Vegeta</character>
        </stars>
        <genre>Animation</genre>
        <genre>Action</genre>
        <genre>Adventure</genre>
    </movie>
</movies>
```

### The command

```tsql
-- ...
SELECT dbo.fn_XMLToJson(@XML, @RET_TAG, @RET_OBJ);
-- ...
```
#### Configurations
* @XML: The xml that will be converted
* @RET_TAG: Accepts 0 or 1. When 1, the first xml tag will be returned otherwise it will not be returned  
* @RET_OBJ: Accepts 0 or 1. When 1 the result will be enclosed by "{" otherwise will not be returned



To convert the above XML to JSON you can run the follow command:

```tsql
DECLARE @XML XML = '<movies>
    <movie>
        <title>Harry Potter and the Prisoner of Azkaban</title>
        <release>2004</release>
        <stars>
            <name>Daniel Radcliffe</name>
            <character>Harry Potter</character>
        </stars>
        <stars>
            <name>Emma Watson</name>
            <character>Hermione Granger</character>
        </stars>
        <stars>
            <name>Rupert Grint</name>
            <character>Ronald Weasley</character>
        </stars>
        <genre>Adventure</genre>
        <genre>Family</genre>
        <genre>Fantasy</genre>
    </movie>
    <movie>
        <title>Dragon Ball Super: Broly</title>
        <release>2018</release>
        <stars>
            <name>D Masako Nozawa (Voice)</name>
            <character>Son Goku</character>
        </stars>
        <stars>
            <name>Aya Hisakawa (Voice)</name>
            <character>Bulma</character>
        </stars>
        <stars>
            <name>Ryô Horikawa (Voice)</name>
            <character>Vegeta</character>
        </stars>
        <genre>Animation</genre>
        <genre>Action</genre>
        <genre>Adventure</genre>
    </movie>
</movies>';
SELECT dbo.fn_XMLToJson(@XML, 1, 1);
```
The return will be:

```json
{
  "movies": {
    "movie": [
      {
        "title": "Harry Potter and the Prisoner of Azkaban",
        "release": "2004",
        "stars": [
          {
            "name": "Daniel Radcliffe",
            "character": "Harry Potter"
          },
          {
            "name": "Emma Watson",
            "character": "Hermione Granger"
          },
          {
            "name": "Rupert Grint",
            "character": "Ronald Weasley"
          }
        ],
        "genre": [
          "Adventure",
          "Family",
          "Fantasy"
        ]
      },
      {
        "title": "Dragon Ball Super: Broly",
        "release": "2018",
        "stars": [
          {
            "name": "D Masako Nozawa (Voice)",
            "character": "Son Goku"
          },
          {
            "name": "Aya Hisakawa (Voice)",
            "character": "Bulma"
          },
          {
            "name": "Ryô Horikawa (Voice)",
            "character": "Vegeta"
          }
        ],
        "genre": [
          "Animation",
          "Action",
          "Adventure"
        ]
      }
    ]
  }
}
```