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

Enhancements with release v2.0.0:

- Support to convert attributes to JSON

USAGE
------------

### The XML

```xml
<movies ref="https://github.com/caio-brendo/mssql-xml2json">
    <movie id="62442">
        <title>Harry Potter and the Prisoner of Azkaban</title>
        <release>2004</release>
        <stars movieId="62442">
            <name>Daniel Radcliffe</name>
            <character>Harry Potter</character>
        </stars>
        <stars movieId="62442">
            <name>Emma Watson</name>
            <character>Hermione Granger</character>
        </stars>
        <stars movieId="62442">
            <name>Rupert Grint</name>
            <character>Ronald Weasley</character>
        </stars>
        <genre>Adventure</genre>
        <genre>Family</genre>
        <genre>Fantasy</genre>
    </movie>
    <movie id="123">
        <title>Dragon Ball Super: Broly</title>
        <release>2018</release>
        <stars movieId="123">
            <name>D Masako Nozawa (Voice)</name>
            <character>Son Goku</character>
        </stars>
        <stars movieId="123">
            <name>Aya Hisakawa (Voice)</name>
            <character>Bulma</character>
        </stars>
        <stars movieId="123">
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
SELECT dbo.fn_XMLToJson(@XML, @RET_TAG, @RET_OBJ, @RET_ATTR);
-- ...
```
#### Configurations
* @XML: The xml that will be converted
* @RET_TAG: Accepts 0 or 1. When 1, the first xml tag will be returned otherwise it will not be returned  
* @RET_OBJ: Accepts 0 or 1. When 1 the result will be enclosed by "{" otherwise will not be returned
* @RET_ATTR: Accepts 0 or 1. When 1 the result will be a JSON with the attributes and values of XML informed



To convert the above XML to JSON without the attributes you can run the follow command:

```tsql
DECLARE @XML VARCHAR(MAX) = '<movies ref="https://github.com/caio-brendo/mssql-xml2json"><movie id="62442"><title>Harry Potter and the Prisoner of Azkaban</title><release>2004</release><stars movieId="62442"><name>Daniel Radcliffe</name><character>Harry Potter</character></stars><stars movieId="62442"><name>Emma Watson</name><character>Hermione Granger</character></stars><stars movieId="62442"><name>Rupert Grint</name><character>Ronald Weasley</character></stars><genre>Adventure</genre><genre>Family</genre><genre>Fantasy</genre></movie><movie id="123"><title>Dragon Ball Super: Broly</title><release>2018</release><stars movieId="123"><name>D Masako Nozawa (Voice)</name><character>Son Goku</character></stars><stars movieId="123"><name>Aya Hisakawa (Voice)</name><character>Bulma</character></stars><stars movieId="123"><name>Ryô Horikawa (Voice)</name><character>Vegeta</character></stars><genre>Animation</genre><genre>Action</genre><genre>Adventure</genre></movie></movies>';
SELECT dbo.fn_XMLToJson(@XML, 1, 1, 0);
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

To convert the above XML to JSON with the attributes you can run the follow command:

```tsql
DECLARE @XML VARCHAR(MAX) = '<movies ref="https://github.com/caio-brendo/mssql-xml2json"><movie id="62442"><title>Harry Potter and the Prisoner of Azkaban</title><release>2004</release><stars movieId="62442"><name>Daniel Radcliffe</name><character>Harry Potter</character></stars><stars movieId="62442"><name>Emma Watson</name><character>Hermione Granger</character></stars><stars movieId="62442"><name>Rupert Grint</name><character>Ronald Weasley</character></stars><genre>Adventure</genre><genre>Family</genre><genre>Fantasy</genre></movie><movie id="123"><title>Dragon Ball Super: Broly</title><release>2018</release><stars movieId="123"><name>D Masako Nozawa (Voice)</name><character>Son Goku</character></stars><stars movieId="123"><name>Aya Hisakawa (Voice)</name><character>Bulma</character></stars><stars movieId="123"><name>Ryô Horikawa (Voice)</name><character>Vegeta</character></stars><genre>Animation</genre><genre>Action</genre><genre>Adventure</genre></movie></movies>';
SELECT dbo.fn_XMLToJson(@XML, 1, 1, 1);
```
The return will be:

```json
{
  "movies": {
    "attributes": {
      "ref": "https://github.com/caio-brendo/mssql-xml2json"
    },
    "values": {
      "movie": [
        {
          "attributes": {
            "id": "62442"
          },
          "values": {
            "title": {
              "attributes": {},
              "values": "Harry Potter and the Prisoner of Azkaban"
            },
            "release": {
              "attributes": {},
              "values": "2004"
            },
            "stars": [
              {
                "attributes": {},
                "values": {
                  "name": {
                    "attributes": {},
                    "values": "Daniel Radcliffe"
                  },
                  "character": {
                    "attributes": {},
                    "values": "Harry Potter"
                  }
                }
              },
              {
                "attributes": {
                  "movieId": "62442"
                },
                "values": {
                  "name": {
                    "attributes": {},
                    "values": "Emma Watson"
                  },
                  "character": {
                    "attributes": {},
                    "values": "Hermione Granger"
                  }
                }
              },
              {
                "attributes": {
                  "movieId": "62442"
                },
                "values": {
                  "name": {
                    "attributes": {},
                    "values": "Rupert Grint"
                  },
                  "character": {
                    "attributes": {},
                    "values": "Ronald Weasley"
                  }
                }
              }
            ],
            "genre": [
              {
                "attributes": {},
                "values": "Adventure"
              },
              {
                "attributes": {},
                "values": "Family"
              },
              {
                "attributes": {},
                "values": "Fantasy"
              }
            ]
          }
        },
        {
          "attributes": {
            "id": "123"
          },
          "values": {
            "title": {
              "attributes": {},
              "values": "Dragon Ball Super: Broly"
            },
            "release": {
              "attributes": {},
              "values": "2018"
            },
            "stars": [
              {
                "attributes": {},
                "values": {
                  "name": {
                    "attributes": {},
                    "values": "D Masako Nozawa (Voice)"
                  },
                  "character": {
                    "attributes": {},
                    "values": "Son Goku"
                  }
                }
              },
              {
                "attributes": {
                  "movieId": "123"
                },
                "values": {
                  "name": {
                    "attributes": {},
                    "values": "Aya Hisakawa (Voice)"
                  },
                  "character": {
                    "attributes": {},
                    "values": "Bulma"
                  }
                }
              },
              {
                "attributes": {
                  "movieId": "123"
                },
                "values": {
                  "name": {
                    "attributes": {},
                    "values": "Ryô Horikawa (Voice)"
                  },
                  "character": {
                    "attributes": {},
                    "values": "Vegeta"
                  }
                }
              }
            ],
            "genre": [
              {
                "attributes": {},
                "values": "Animation"
              },
              {
                "attributes": {},
                "values": "Action"
              },
              {
                "attributes": {},
                "values": "Adventure"
              }
            ]
          }
        }
      ]
    }
  }
}
```

You can generate a xml from select and then generate a JSON. E.g:

```tsql
DECLARE @movies
    TABLE(
             id INT,
             title VARCHAR(200)
         );
INSERT INTO @movies
    (id, title)
VALUES (62442, 'Harry Potter'),
       (123, 'Dragon Ball Super: Broly');

DECLARE @xml VARCHAR(MAX) = (SELECT *
                             FROM @movies
                             FOR XML PATH ('movies'));
SELECT dbo.fn_XMLToJson(@XML, 1, 1, 0);
```

The return will be:

```json
{
  "movies": [
    {
      "id": "62442",
      "title": "Harry Potter"
    },
    {
      "id": "123",
      "title": "Dragon Ball Super: Broly"
    }
  ]
}
```