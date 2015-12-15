CREATE TABLE schemaVersion (version INTEGER);
CREATE TABLE media (
    id INTEGER PRIMARY KEY,
    filename TEXT UNIQUE NOT NULL CHECK (filename LIKE '/%'),
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
CREATE INDEX media_type_idx ON media(type);
CREATE INDEX media_song_info_idx ON media(type, album_artist, album, disc_number, track_number, title) WHERE type = 1;
CREATE INDEX media_artist_idx ON media(type, artist) WHERE type = 1;
CREATE INDEX media_genre_idx ON media(type, genre) WHERE type = 1;
CREATE INDEX media_mtime_idx ON media(type, mtime);
CREATE TABLE media_attic (
    id INTEGER PRIMARY KEY,
    filename TEXT UNIQUE NOT NULL,
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
    has_thumbnail INTEGER,
    mtime INTEGER,
    type INTEGER   -- 0=Audio, 1=Video
);
CREATE VIRTUAL TABLE media_fts
USING fts4(content='media', title, artist, album, tokenize=mozporter);
CREATE TABLE 'media_fts_segments'(blockid INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE 'media_fts_segdir'(level INTEGER,idx INTEGER,start_block INTEGER,leaves_end_block INTEGER,end_block INTEGER,root BLOB,PRIMARY KEY(level, idx));
CREATE TABLE 'media_fts_docsize'(docid INTEGER PRIMARY KEY, size BLOB);
CREATE TABLE 'media_fts_stat'(id INTEGER PRIMARY KEY, value BLOB);
CREATE TRIGGER media_bu BEFORE UPDATE ON media BEGIN
  DELETE FROM media_fts WHERE docid=old.id;
END;
CREATE TRIGGER media_au AFTER UPDATE ON media BEGIN
  INSERT INTO media_fts(docid, title, artist, album) VALUES (new.id, new.title, new.artist, new.album);
END;
CREATE TRIGGER media_bd BEFORE DELETE ON media BEGIN
  DELETE FROM media_fts WHERE docid=old.id;
END;
CREATE TRIGGER media_ai AFTER INSERT ON media BEGIN
  INSERT INTO media_fts(docid, title, artist, album) VALUES (new.id, new.title, new.artist, new.album);
END;
CREATE TABLE broken_files (
    filename TEXT PRIMARY KEY NOT NULL,
    etag TEXT NOT NULL
);
