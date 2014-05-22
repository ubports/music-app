BEGIN TRANSACTION;
DROP TABLE media;
CREATE TABLE media (
    filename TEXT PRIMARY KEY NOT NULL,
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
    type INTEGER   -- 0=Audio, 1=Video
);
INSERT INTO media VALUES('/home/phablet/Music/1.ogg','audio/ogg','1400569935:0','Gran Vals',1902,'Francisco Tárrega','','Francisco Tárrega','',0,0,202,1);
INSERT INTO media VALUES('/home/phablet/Music/2.ogg','audio/ogg','1399334632:0','Swansong','','Josh Woodward','','Josh Woodward','',0,0,62,1);
INSERT INTO media VALUES('/home/phablet/Music/3.mp3','audio/mpeg','1399334632:0','TestMP3Title','','TestMP3Artist','TestMP3Album','TestMP3Artist','',0,0,6,1);

CREATE INDEX media_album_album_artist_idx ON media(album, album_artist);
CREATE TRIGGER media_ai AFTER INSERT ON media BEGIN
  INSERT INTO media_fts(docid, title, artist, album) VALUES (new.rowid, new.title, new.artist, new.album);
END;
CREATE TRIGGER media_au AFTER UPDATE ON media BEGIN
  INSERT INTO media_fts(docid, title, artist, album) VALUES (new.rowid, new.title, new.artist, new.album);
END;
CREATE TRIGGER media_bd BEFORE DELETE ON media BEGIN
  DELETE FROM media_fts WHERE docid=old.rowid;
END;
CREATE TRIGGER media_bu BEFORE UPDATE ON media BEGIN
  DELETE FROM media_fts WHERE docid=old.rowid;
END;
COMMIT;
