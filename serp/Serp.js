.pragma library

var theme = null;
var mpris = null;
var spectrum = null;
var lyrics = null;

function use(ctx) {
    theme = ctx;
    mpris = ctx ? ctx.mpris : null;
    spectrum = ctx ? ctx.spectrum : null;
    lyrics = ctx ? ctx.lyrics : null;
}

function drop(ctx) {
    if (theme === ctx) use(null);
}

function tr(key, args) {
    return theme ? theme.tr(key, args) : (typeof args === "string" ? args : key);
}

function s(value) {
    return theme ? theme.s(value) : value;
}

function fs(value) {
    return theme ? theme.fs(value) : value;
}

function sfx(file, volume) {
    if (theme) theme.playSfx(file, volume);
}
