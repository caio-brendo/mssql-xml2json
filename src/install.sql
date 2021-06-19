IF (OBJECT_ID('fn_normalizeStringJson') IS NOT NULL)
    BEGIN
        DROP FUNCTION fn_normalizeStringJson;
    END
GO
--===============================( A T U A L I Z A Ç Ã O )===============================================================
--> Autor							              Data         Resumo
--> -----------------------------               ----------   -----------
--> Caio Brendo <caioaraujo.immv@gmail.com>     04/06/2021   v1.0.0: Remove invalid characters
--=======================================================================================================================
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
--======================================== (CRIAÇÃO) =======================================================
--> Autor                                         Data         Resumo
--> -----------------------------               ----------   -----------
--> Caio Brendo <caioaraujo.immv@gmail.com>     04/06/2021   v1.0.0: Return all xml tags and their content
--=========================================================================================================
CREATE FUNCTION fn_XMLTagsContents(@XML XML)
    RETURNS @tbl TABLE
                 (
                     id          BIGINT IDENTITY NOT NULL PRIMARY KEY,
                     nm_tag      VARCHAR(100)    NOT NULL UNIQUE (id, nm_tag),
                     content     VARCHAR(MAX)    NULL,
                     content_xml BIT             NOT NULL DEFAULT 1,
                     xml         VARCHAR(MAX)    NULL,
                     tag_unique  BIT             NOT NULL DEFAULT 1
                 )
AS
BEGIN
    -- Casting xml to string
    DECLARE @xmlStr VARCHAR(MAX) = CAST(@XML AS VARCHAR(MAX));

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

    DECLARE @tagComplete VARCHAR(MAX);
    DECLARE @tagCompleteClose VARCHAR(MAX);
    DECLARE @xmlInternal VARCHAR(MAX);
    DECLARE @lenTagComplete BIGINT;
    DECLARE @lenTagCompleteClose BIGINT;

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
            SET @tagComplete = SUBSTRING(@xmlStr, @tagBegin, @tagEnd);
            SET @lenTagComplete = LEN(@tagComplete);

            -- Checks if the tag content is empty
            IF (SUBSTRING(@tagComplete, @lenTagComplete - 1, 1) = '/')
                BEGIN
                    SET @tag = SUBSTRING(@tagComplete, 2, @lenTagComplete - 3);
                    SET @tagCompleteClose = '<' + @tag + '/>';
                    SET @closedTag = CHARINDEX(@tagCompleteClose, @xmlStr);
                    -- - If it doesn't find the close tag it concatenates with the next string
                    WHILE @closedTag = 0
                        BEGIN
                            SET @cont += 1;
                            SET @xmlStr += (SELECT content FROM @tblContent WHERE id = @cont);
                            SET @closedTag = CHARINDEX(@tagCompleteClose, @xmlStr);
                        END
                    SET @xmlInternal = NULL;
                    SET @content = NULL;
                END
            ELSE
                BEGIN
                    SET @tag = SUBSTRING(@tagComplete, 2, @lenTagComplete - 2);
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
            INSERT INTO @tbl (nm_tag, content, xml, content_xml, tag_unique)
            VALUES (@tag,
                    @content,
                    @xmlInternal,
                    CASE WHEN CHARINDEX('<', @content) <> 0 THEN 1 ELSE 0 END,
                    CASE WHEN EXISTS(SELECT 1 FROM @tbl WHERE nm_tag = @tag) THEN 0 ELSE 1 END);

            UPDATE @tbl SET tag_unique = 0 WHERE nm_tag = @tag AND id <> SCOPE_IDENTITY();

            -- Remove the tag found in the xml
            SET @xmlStr = STUFF(@xmlStr, @tagBegin, LEN(@xmlInternal), '');
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
IF (OBJECT_ID('fn_XMLToJson') IS NOT NULL)
    BEGIN
        DROP FUNCTION fn_XMLToJson;
    END
GO
--======================================== (CRIAÇÃO) =======================================================
--> Autor                                         Data         Resumo
--> -----------------------------               ----------   -----------
--> Caio Brendo <caioaraujo.immv@gmail.com>     04/06/2021   v1.0.0: Cast xml to JSON
--=========================================================================================================
CREATE FUNCTION fn_XMLToJson(@XML XML, @RET_TAG BIT = 1, @RET_OBJ BIT = 1) RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @tag VARCHAR(MAX);
    DECLARE @isXml BIT;
    DECLARE @content VARCHAR(MAX);
    DECLARE @json VARCHAR(MAX) = '';
    DECLARE @isUnique BIT;
    DECLARE @xmlInternal VARCHAR(MAX);
    DECLARE @tblXml TABLE
                    (
                        id          BIGINT,
                        nm_tag      VARCHAR(MAX),
                        content     VARCHAR(MAX),
                        content_xml BIT,
                        xml         VARCHAR(MAX),
                        tag_unique  BIT
                    );
    DECLARE @id BIGINT;
    DECLARE @lastChar CHAR(1);

    INSERT INTO @tblXml
    SELECT *
    FROM fn_XMLTagsContents(@XML);

    SELECT TOP 1 @id = id,
                 @tag = nm_tag,
                 @content = content,
                 @isXml = content_xml,
                 @xmlInternal = xml,
                 @isUnique = tag_unique
    FROM @tblXml

    WHILE (@tag IS NOT NULL)
        BEGIN
            IF (@isXml = 0)
                BEGIN
                    IF (@isUnique = 0)
                        BEGIN
                            SET @lastChar = RIGHT(@json, 1);
                            IF (@lastChar IN ('"', '}', ']'))
                                BEGIN
                                    SET @json += ', ';
                                END
                            SET @json += +'"' + @tag + '": ["' + dbo.fn_normalizeStringJson(@content) + '", ';
                            SET @json += (SELECT STUFF((SELECT ', ' + ret
                                                        FROM (
                                                                 SELECT dbo.fn_XMLToJson(xml, 0, 0) as ret
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
                            IF (@lastChar IN ('"', ']'))
                                SET @json += ', ';
                            IF (@RET_TAG = 0)
                                SET @json += '"' + dbo.fn_normalizeStringJson(@content) + '"';
                            ELSE
                                SET @json += '"' + @tag + '": "' + dbo.fn_normalizeStringJson(@content) + '"';
                        END
                    SET @RET_TAG = 1;
                END
            ELSE
                BEGIN
                    DECLARE @out VARCHAR(MAX);
                    IF (@isUnique = 0)
                        BEGIN
                            SET @out = (SELECT dbo.fn_XMLToJson(@content, 1, 1));
                            SET @lastChar = RIGHT(@json, 1);
                            IF (@lastChar IN ('"', '}'))
                                BEGIN
                                    SET @json += ', ';
                                END
                            IF (@RET_TAG = 1)
                                SET @json += +'"' + @tag + '": [' + @out + ', ';
                            ELSE
                                SET @json += +'[' + @out + ', ';
                            SET @json += (SELECT STUFF((SELECT ', ' + ret
                                                        FROM (
                                                                 SELECT dbo.fn_XMLToJson(xml, 0, 0) as ret
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
                            SET @out = (SELECT dbo.fn_XMLToJson(@content, 1, 1));
                            IF (@RET_TAG = 1)
                                BEGIN
                                    SET @lastChar = RIGHT(@json, 1);
                                    IF (@lastChar IN ('"', '}'))
                                        SET @json+= ', ';
                                    SET @json += '"' + @tag + '": ' + @out + '';
                                END
                            ELSE
                                BEGIN
                                    IF (SUBSTRING(@json, LEN(@json), 1) = '"')
                                        BEGIN
                                            SET @json+= ', ';
                                        END
                                    SET @json += @out + '';
                                END
                            SET @RET_TAG = 1;
                        END
                END

            DELETE FROM @tblXml WHERE id = @id;
            SET @tag = (SELECT TOP 1 nm_tag FROM @tblXml);

            SELECT TOP 1 @id = id, @content = content, @isXml = content_xml, @xmlInternal = xml, @isUnique = tag_unique
            FROM @tblXml
        END
    IF (@RET_OBJ = 1)
        SET @json = '{' + @json + '}';

    RETURN @json;
END