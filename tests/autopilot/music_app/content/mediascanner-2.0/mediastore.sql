BEGIN TRANSACTION;
DELETE FROM `schemaVersion`;
INSERT INTO `schemaVersion` VALUES(9);

DROP TABLE media;
CREATE TABLE media (
    filename TEXT PRIMARY KEY NOT NULL CHECK (filename LIKE '/%'),
    content_type TEXT,
    etag TEXT,
    title TEXT,
    date TEXT,
    artist TEXT,          -- Only relevant to audio
    album TEXT,           -- Only relevant to audio
    album_artist TEXT,    -- Only relevant to audio
    genre TEXT,           -- Only relevant to audio
    disc_number INTEGER,  -- Only relevant to audio
    track_number INTEGER, -- Only relevant to audio
    duration INTEGER,
    width INTEGER,        -- Only relevant to video/images
    height INTEGER,       -- Only relevant to video/images
    latitude DOUBLE,
    longitude DOUBLE,
    has_thumbnail INTEGER CHECK (has_thumbnail IN (0, 1)),
    mtime INTEGER,
    type INTEGER CHECK (type IN (1, 2, 3)) -- MediaType enum
);
INSERT INTO `media` VALUES('/home/phablet/Music/1.ogg','audio/ogg','1409807154:648352','Gran Vals',1902,'Francisco Tárrega','','Francisco Tárrega','',0,0,202,0,0,'0.0','0.0',0,1409807154,1);
INSERT INTO `media` VALUES('/home/phablet/Music/2.ogg','audio/ogg','1409807154:658363','Swansong','','Josh Woodward','','Josh Woodward','',0,0,62,0,0,'0.0','0.0',0,1409807154,1);
INSERT INTO `media` VALUES('/home/phablet/Music/3.mp3','audio/mpeg','1409807154:658363','TestMP3Title','','TestMP3Artist','TestMP3Album','TestMP3Artist','',0,0,6,0,0,'0.0','0.0',0,1409807154,1);

CREATE INDEX media_type_idx ON media(type);
CREATE INDEX media_song_info_idx ON media(type, album_artist, album, disc_number, track_number, title) WHERE type = 0;
CREATE INDEX media_genre_idx ON media(type, genre) WHERE type = 0;
CREATE INDEX media_artist_idx ON media(type, artist) WHERE type = 0;
CREATE TRIGGER media_bu BEFORE UPDATE ON media BEGIN
  DELETE FROM media_fts WHERE docid=old.rowid;
END;
CREATE TRIGGER media_bd BEFORE DELETE ON media BEGIN
  DELETE FROM media_fts WHERE docid=old.rowid;
END;
CREATE TRIGGER media_au AFTER UPDATE ON media BEGIN
  INSERT INTO media_fts(docid, title, artist, album) VALUES (new.rowid, new.title, new.artist, new.album);
END;
CREATE TRIGGER media_ai AFTER INSERT ON media BEGIN
  INSERT INTO media_fts(docid, title, artist, album) VALUES (new.rowid, new.title, new.artist, new.album);
END;
COMMIT;
