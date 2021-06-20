IF (OBJECT_ID('fn_trimString') IS NOT NULL)
    BEGIN
        DROP FUNCTION fn_trimString;
    END
GO
--======================================== (H I S T O R Y) =======================================================
--> Author                                      Date         Resume
--> -----------------------------               ----------   -----------
--> Caio Brendo <caioaraujo.immv@gmail.com>     20/06/2021   v2.0.0: Trim string
--===============================================================================================================
IF (OBJECT_ID('fn_trimString') IS NOT NULL)
    BEGIN
        DROP FUNCTION fn_trimString;
    END
GO
CREATE FUNCTION fn_trimString(@STRING VARCHAR(MAX)) RETURNS VARCHAR(MAX)
AS
BEGIN
    RETURN RTRIM(LTRIM(@STRING));
END
GO
IF (OBJECT_ID('fn_normalizeStringJson') IS NOT NULL)
    BEGIN
        DROP FUNCTION fn_normalizeStringJson;
    END
GO
--===============================( H I S T O R Y )===============================================================
--> Author                                      Date         Resume
--> -----------------------------               ----------   -----------
--> Caio Brendo <caioaraujo.immv@gmail.com>     04/06/2021   v1.0.0: Remove invalid characters
--===============================================================================================================
CREATE FUNCTION fn_normalizeStringJson(@STRING VARCHAR(MAX)) RETURNS VARCHAR(MAX)
AS
BEGIN
    -- Removing "
    SET @STRING = REPLACE(@STRING, '"', '\"');
    -- Removing tab
    SET @STRING = REPLACE(@STRING, CHAR(9), '\t');
    -- Removing enter
    SET @STRING = REPLACE(@STRING, CHAR(13), '\n');
    -- Removing enter
    SET @STRING = REPLACE(@STRING, CHAR(10), '\n');

    RETURN @STRING;
END
GO
IF (OBJECT_ID('fn_XMLTagsContents') IS NOT NULL)
    BEGIN
        DROP FUNCTION fn_XMLTagsContents;
    END
GO
--======================================== (H I S T O R Y) =======================================================
--> Author                                      Date         Resume
--> -----------------------------               ----------   -----------
--> Caio Brendo <caioaraujo.immv@gmail.com>     04/06/2021   v1.0.0: Return all xml tags and their content
--> Caio Brendo <caioaraujo.immv@gmail.com>     20/06/2021   v2.0.0: Add return of attributes xml
--================================================================================================================
CREATE FUNCTION fn_XMLTagsContents(@XML VARCHAR(MAX))
    RETURNS @tbl TABLE
                 (
                     id          BIGINT IDENTITY NOT NULL PRIMARY KEY,
                     nm_tag      VARCHAR(100)    NOT NULL UNIQUE (id, nm_tag),
                     content     VARCHAR(MAX)    NULL,
                     content_xml BIT             NOT NULL DEFAULT 1,
                     xml         VARCHAR(MAX)    NULL,
                     tag_unique  BIT             NOT NULL DEFAULT 1,
                     attributes  VARCHAR(MAX)    NULL
                 )
AS
BEGIN
    -- Casting xml to string
    DECLARE @xmlStr VARCHAR(MAX) = @XML;

    -- Quantity of char by string
    DECLARE @qtd BIGINT = 300000;
    DECLARE @tblContent TABLE
                        (
                            id      INT NOT NULL IDENTITY PRIMARY KEY,
                            content VARCHAR(MAX)
                        );
    -- Split string every 300000 chars
    WHILE @xmlStr IS NOT NULL AND @xmlStr <> ''
        BEGIN
            INSERT INTO @tblContent (content) VALUES (LEFT(@xmlStr, @qtd));
            SET @xmlStr = STUFF(@xmlStr, 1, @qtd, '');
        END

    DECLARE @cont BIGINT = 1;

    -- Start by first line
    SET @xmlStr = (SELECT content FROM @tblContent WHERE id = @cont);

    DECLARE @tagBegin BIGINT;
    DECLARE @tagEnd BIGINT;
    DECLARE @tag VARCHAR(MAX);
    DECLARE @closedTag BIGINT;
    DECLARE @content VARCHAR(MAX);
    DECLARE @attributes VARCHAR(MAX);

    DECLARE @tagComplete VARCHAR(MAX);
    DECLARE @tagCompleteClose VARCHAR(MAX);
    DECLARE @xmlInternal VARCHAR(MAX);
    DECLARE @lenTagComplete BIGINT;
    DECLARE @lenTagCompleteClose BIGINT;
    DECLARE @space BIGINT;
    DECLARE @lenXmlInternal BIGINT;

    -- Making loop in xml finding some tag
    WHILE (CHARINDEX('<', @xmlStr) <> 0)
        BEGIN
            SET @tagBegin = CHARINDEX('<', @xmlStr);
            -- - If it doesn't find the start tag it concatenates with the next string
            WHILE @tagBegin = 0
                BEGIN
                    SET @cont += 1;
                    SET @xmlStr += (SELECT content FROM @tblContent WHERE id = @cont);
                    SET @tagBegin = CHARINDEX('<', @xmlStr);
                END
            SET @tagEnd = CHARINDEX('>', @xmlStr);
            -- - If it doesn't find the close tag it concatenates with the next string
            WHILE @tagEnd = 0
                BEGIN
                    SET @cont += 1;
                    SET @xmlStr += (SELECT content FROM @tblContent WHERE id = @cont);
                    SET @tagEnd = CHARINDEX('>', @xmlStr);
                END
            SET @tagComplete = SUBSTRING(@xmlStr, @tagBegin, @tagEnd - @tagBegin + 1);

            SET @lenTagComplete = LEN(@tagComplete);

            -- If has space in tag then has attribute
            SET @space = CHARINDEX(' ', @tagComplete);

            -- Checks if the tag content is empty
            IF (SUBSTRING(@tagComplete, @lenTagComplete - 1, 1) = '/')
                BEGIN

                    SET @tag = CASE @space
                                   WHEN 0
                                       THEN SUBSTRING(@tagComplete, 2, @lenTagComplete - 3)
                                   ELSE SUBSTRING(@tagComplete, 2, @space - 2)
                        END

                    SET @attributes = CASE @space
                                          WHEN 0
                                              THEN NULL
                                          ELSE SUBSTRING(@tagComplete, @space + 1, @lenTagComplete - @space - 2)
                        END

                    SET @closedTag = CHARINDEX('/>', @xmlStr);
                    -- - If it doesn't find the close tag it concatenates with the next string
                    WHILE @closedTag = 0
                        BEGIN
                            SET @cont += 1;
                            SET @xmlStr += (SELECT content FROM @tblContent WHERE id = @cont);
                            SET @closedTag = CHARINDEX('/>', @xmlStr);
                        END
                    SET @xmlInternal = @tagComplete;
                    SET @content = '';
                END
            ELSE
                BEGIN
                    SET @tag = CASE @space
                                   WHEN 0
                                       THEN SUBSTRING(@tagComplete, 2, @lenTagComplete - 2)
                                   ELSE SUBSTRING(@tagComplete, 2, @space - 2)
                        END

                    SET @attributes = CASE @space
                                          WHEN 0
                                              THEN NULL
                                          ELSE SUBSTRING(@tagComplete, @space + 1, @lenTagComplete - @space - 1)
                        END

                    SET @tagCompleteClose = '</' + @tag + '>';
                    SET @lenTagCompleteClose = LEN(@tagCompleteClose);
                    SET @closedTag = CHARINDEX(@tagCompleteClose, @xmlStr);
                    -- - If it doesn't find the closed tag it concatenates with the next string
                    WHILE @closedTag = 0
                        BEGIN
                            SET @cont += 1;
                            SET @xmlStr += (SELECT content FROM @tblContent WHERE id = @cont);
                            SET @closedTag = CHARINDEX(@tagCompleteClose, @xmlStr);
                        END
                    SET @xmlInternal = SUBSTRING(@xmlStr, @tagBegin, @closedTag + @lenTagCompleteClose - 1);
                    SET @content = SUBSTRING(@xmlInternal, @lenTagComplete + 1,
                                             LEN(@xmlInternal) - @lenTagComplete - @lenTagCompleteClose);
                END
            INSERT INTO @tbl (nm_tag, content, xml, content_xml, tag_unique, attributes)
            VALUES (@tag,
                    @content,
                    @xmlInternal,
                    CASE WHEN CHARINDEX('<', @content) <> 0 THEN 1 ELSE 0 END,
                    CASE WHEN EXISTS(SELECT 1 FROM @tbl WHERE nm_tag = @tag) THEN 0 ELSE 1 END,
                    @attributes);

            UPDATE @tbl SET tag_unique = 0 WHERE nm_tag = @tag AND id <> SCOPE_IDENTITY();

            SET @lenXmlInternal = ISNULL(LEN(@xmlInternal), 0);
            -- Remove the tag found in the xml
            SET @xmlStr = STUFF(@xmlStr, @tagBegin,
                                CASE @lenXmlInternal WHEN 0 THEN @tagEnd - @tagBegin + 1 ELSE @lenXmlInternal END, '');
            -- - If xml is null then concatenates with next string
            IF @xmlStr IS NULL OR @xmlStr = ''
                BEGIN
                    SET @cont += 1;
                    SET @xmlStr += (SELECT content FROM @tblContent WHERE id = @cont);
                END
        END

    RETURN;
END
GO
IF (OBJECT_ID('fn_XMLAttributesContents') IS NOT NULL)
    BEGIN
        DROP FUNCTION fn_XMLAttributesContents;
    END
GO
--======================================== (H I S T O R Y) =======================================================
--> Author                                      Date         Resume
--> -----------------------------               ----------   -----------
--> Caio Brendo <caioaraujo.immv@gmail.com>     20/06/2021   v2.0.0: Return all xml attributes and their content
--================================================================================================================
CREATE FUNCTION fn_XMLAttributesContents(@ATTRIBUTES VARCHAR(MAX))
    RETURNS @tbl TABLE
                 (
                     id           BIGINT IDENTITY NOT NULL PRIMARY KEY,
                     nm_attribute VARCHAR(100)    NOT NULL UNIQUE (id, nm_attribute),
                     content      VARCHAR(MAX)    NULL,
                     attribute    VARCHAR(MAX)    NULL
                 )
AS
BEGIN
    DECLARE @attributeEnd BIGINT;
    DECLARE @attr VARCHAR(MAX);
    DECLARE @content VARCHAR(MAX);
    DECLARE @attributeComplete VARCHAR(MAX);
    DECLARE @lenAttributeComplete BIGINT;

    -- Making loop in string finding some attribute
    WHILE (@ATTRIBUTES IS NOT NULL AND @ATTRIBUTES <> '')
        BEGIN
            SET @attributeEnd = CHARINDEX('"', LTRIM(@ATTRIBUTES));
            SET @attributeEnd = CHARINDEX('"', LTRIM(@ATTRIBUTES), @attributeEnd + 1);

            SET @attributeComplete = SUBSTRING(@ATTRIBUTES, 1, @attributeEnd + 1);

            SET @lenAttributeComplete = LEN(@attributeComplete);
            SET @attr = SUBSTRING(@attributeComplete, 1, CHARINDEX('=', @attributeComplete) - 1);
            SET @content = SUBSTRING(@attributeComplete, CHARINDEX('=', @attributeComplete) + 2,
                                     @lenAttributeComplete - LEN(@attr) - 3);
            INSERT INTO @tbl (nm_attribute, content, attribute)
            VALUES (@attr,
                    @content,
                    @attributeComplete);

            -- Remove the tag found in the xml
            SET @ATTRIBUTES = dbo.fn_trimString(STUFF(@ATTRIBUTES, 1, LEN(@attributeComplete), ''));
        END

    RETURN;
END
GO
IF (OBJECT_ID('fn_XMLAttributesToJson') IS NOT NULL)
    BEGIN
        DROP FUNCTION fn_XMLAttributesToJson;
    END
GO
--======================================== (H I S T O R Y) =======================================================
--> Author                                      Date         Resume
--> -----------------------------               ----------   -----------
--> Caio Brendo <caioaraujo.immv@gmail.com>     04/06/2021   v2.0.0: Return the xml attributes informed in json format
--================================================================================================================
CREATE FUNCTION fn_XMLAttributesToJson(@ATTRIBUTES VARCHAR(MAX))
    RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @json VARCHAR(MAX) = '';
    DECLARE @nmAttribute VARCHAR(MAX);
    DECLARE @content VARCHAR(MAX);
    DECLARE @id BIGINT;
    DECLARE @tblAttr TABLE
                     (
                         id           BIGINT       NOT NULL PRIMARY KEY,
                         nm_attribute VARCHAR(100) NOT NULL UNIQUE (id, nm_attribute),
                         content      VARCHAR(MAX) NULL,
                         attribute    VARCHAR(MAX) NULL
                     );
    INSERT INTO @tblAttr (id, nm_attribute, content)
    SELECT id, nm_attribute, content
    FROM dbo.fn_XMLAttributesContents(@ATTRIBUTES);

    SELECT TOP 1 @id = id, @nmAttribute = nm_attribute, @content = content FROM @tblAttr;

    WHILE (@nmAttribute IS NOT NULL)
        BEGIN
            IF (@json <> '')
                BEGIN
                    SET @json += ', ';
                END
            SET @json += '"' + @nmAttribute + '": "' + dbo.fn_normalizeStringJson(@content) + '"'

            DELETE FROM @tblAttr WHERE id = @id;
            SET @nmAttribute = (SELECT TOP 1 nm_attribute FROM @tblAttr);
            SELECT TOP 1 @id = id, @content = content FROM @tblAttr;
        END

    RETURN '{' + @json + '}';
END
GO
IF (OBJECT_ID('fn_XMLToJson') IS NOT NULL)
    BEGIN
        DROP FUNCTION fn_XMLToJson;
    END
GO
--======================================== (H I S T O R Y) =======================================================
--> Author                                      Date         Resume
--> -----------------------------               ----------   -----------
--> Caio Brendo <caioaraujo.immv@gmail.com>     04/06/2021   v1.0.0: Cast xml to JSON
--> Caio Brendo <caioaraujo.immv@gmail.com>     20/06/2021   v2.0.0: Add support to attributes
--===============================================================================================================
CREATE FUNCTION fn_XMLToJson(@XML VARCHAR(MAX), @RET_TAG BIT = 1, @RET_OBJ BIT = 1,
                             @RET_ATTRS BIT = 0) RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @tag VARCHAR(MAX);
    DECLARE @isXml BIT;
    DECLARE @content VARCHAR(MAX);
    DECLARE @json VARCHAR(MAX) = '';
    DECLARE @isUnique BIT;
    DECLARE @xmlInternal VARCHAR(MAX);
    DECLARE @attributes VARCHAR(MAX);
    DECLARE @tblXml TABLE
                    (
                        id          BIGINT,
                        nm_tag      VARCHAR(MAX),
                        content     VARCHAR(MAX),
                        content_xml BIT,
                        xml         VARCHAR(MAX),
                        tag_unique  BIT,
                        attributes  VARCHAR(MAX) NULL
                    );
    DECLARE @id BIGINT;
    DECLARE @lastChar CHAR(1);

    INSERT INTO @tblXml
    SELECT *
    FROM fn_XMLTagsContents(@XML);

    SELECT TOP 1 @id = id,
                 @tag = nm_tag,
                 @content = ISNULL(content, ''),
                 @isXml = content_xml,
                 @xmlInternal = xml,
                 @isUnique = tag_unique,
                 @attributes = attributes
    FROM @tblXml

    WHILE (@tag IS NOT NULL)
        BEGIN
            IF (@isXml = 0)
                BEGIN
                    IF (@isUnique = 0)
                        BEGIN
                            SET @lastChar = RIGHT(@json, 1);
                            SET @json += CASE WHEN @lastChar IN ('"', '}', ']') THEN ', ' ELSE '' END;
                            IF (@RET_ATTRS = 0)
                                BEGIN
                                    SET @json += +'"' + @tag + '": ["' + dbo.fn_normalizeStringJson(@content) + '", ';
                                END
                            ELSE
                                BEGIN
                                    SET @json += +'"' + @tag + '": [{"attributes": ' +
                                                 dbo.fn_XMLAttributesToJson(@attributes) + ', "values": "' +
                                                 dbo.fn_normalizeStringJson(@content) + '"}, ';
                                END
                            SET @json += (SELECT STUFF((SELECT ', ' + ret
                                                        FROM (
                                                                 SELECT dbo.fn_XMLToJson(xml, 0, 0, @RET_ATTRS) as ret
                                                                 FROM @tblXml
                                                                 WHERE id <> @id
                                                                   AND nm_tag = @tag
                                                             ) x
                                                        FOR XML PATH('')
                                                       ), 1, 2, ''));
                            SET @json += ']';
                            DELETE FROM @tblXml WHERE id <> @id AND nm_tag = @tag;
                        END
                    ELSE
                        BEGIN
                            SET @lastChar = RIGHT(@json, 1);
                            SET @json +=
                                CASE WHEN @lastChar IN ('"', '}', ']') THEN ',' ELSE '' END
                            IF (@RET_ATTRS = 0)
                                BEGIN
                                    SET @json +=
                                        CASE @RET_TAG
                                            WHEN 0 THEN '"' + dbo.fn_normalizeStringJson(@content) + '"'
                                            ELSE '"' + @tag + '": "' + dbo.fn_normalizeStringJson(@content) + '"'
                                            END;
                                END
                            ELSE
                                BEGIN
                                    SET @json +=
                                        CASE @RET_TAG
                                            WHEN 0 THEN '{"attributes": ' + dbo.fn_XMLAttributesToJson(@attributes) +
                                                        ', "values": "' + dbo.fn_normalizeStringJson(@content) + '"}'
                                            ELSE '"' + @tag + '": {"attributes": ' +
                                                 dbo.fn_XMLAttributesToJson(@attributes) + ', "values": "' +
                                                 dbo.fn_normalizeStringJson(@content) + '"}'
                                            END
                                END
                        END
                    SET @RET_TAG = 1;
                END
            ELSE
                BEGIN
                    DECLARE @out VARCHAR(MAX);
                    IF (@isUnique = 0)
                        BEGIN
                            SET @out = (SELECT dbo.fn_XMLToJson(@content, 1, 1, @RET_ATTRS));
                            SET @lastChar = RIGHT(@json, 1);
                            IF (@lastChar IN ('"', '}', ']'))
                                BEGIN
                                    SET @json += ', ';
                                END
                            IF (@RET_ATTRS = 0)
                                BEGIN
                                    SET @json += CASE @RET_TAG
                                                     WHEN 1 THEN '"' + @tag + '": [' + @out + ', '
                                                     ELSE '[' + @out + ', ' END
                                END
                            ELSE
                                BEGIN
                                    SET @json += CASE @RET_TAG
                                                     WHEN 1
                                                         THEN '"' + @tag + '": [{"attributes": ' +
                                                              dbo.fn_XMLAttributesToJson(@attributes) +
                                                              ', "values": ' + @out + '}, '
                                                     ELSE '[{attributes: ' + dbo.fn_XMLAttributesToJson(@attributes) +
                                                          ', "values": ' + @out + '}, ' END
                                END
                            SET @json += (SELECT STUFF((SELECT ', ' + ret
                                                        FROM (
                                                                 SELECT dbo.fn_XMLToJson(xml, 0, 0, @RET_ATTRS) as ret
                                                                 FROM @tblXml
                                                                 WHERE id <> @id
                                                                   AND nm_tag = @tag
                                                             ) x
                                                        FOR XML PATH('')
                                                       ), 1, 2, ''));
                            SET @json += ']';
                            DELETE FROM @tblXml WHERE id <> @id AND nm_tag = @tag
                        END
                    ELSE
                        BEGIN
                            SET @out = (SELECT dbo.fn_XMLToJson(@content, 1, 1, @RET_ATTRS));
                            SET @lastChar = RIGHT(@json, 1);
                            IF (@lastChar IN ('"', '}', ']'))
                                SET @json+= ', ';
                            IF (@RET_ATTRS = 0)
                                BEGIN
                                    SET @json += CASE @RET_TAG WHEN 1 THEN '"' + @tag + '": ' + @out + '' ELSE @out END
                                END
                            ELSE
                                BEGIN
                                    SET @json += CASE @RET_TAG
                                                     WHEN 1
                                                         THEN '"' + @tag + '": {"attributes": ' +
                                                              dbo.fn_XMLAttributesToJson(@attributes) + ', "values": ' +
                                                              @out + '}'
                                                     ELSE '{"attributes": ' + dbo.fn_XMLAttributesToJson(@attributes) +
                                                          ', "values": ' + @out + '}'
                                        END
                                END
                            SET @RET_TAG = 1;
                        END
                END

            DELETE FROM @tblXml WHERE id = @id;
            SET @tag = (SELECT TOP 1 nm_tag FROM @tblXml);

            SELECT TOP 1 @id = id,
                         @content = ISNULL(content, ''),
                         @isXml = content_xml,
                         @xmlInternal = xml,
                         @isUnique = tag_unique
            FROM @tblXml
        END
    IF (@RET_OBJ = 1)
        SET @json = '{' + @json + '}';

    RETURN @json;
END