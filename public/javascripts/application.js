var IMM = {};

IMM.Filmstrip = function() {

  this.photos = [];

  this.displayNode = $("#filmstrip")[0];

};

IMM.Filmstrip.prototype.loadAlbum = function(id) {
  var context = this;
  $.ajax({
    type: 'GET',
    url: "/page/load_album_images?id=" + id,
    success: context.onLoadAlbumSuccess,
    dataType: "json",
    error: context.onLoadAlbumError
  });
};

IMM.Filmstrip.prototype.onLoadAlbumSuccess = function(json, httpCode, xmlHttpRequest) {
  var context = IMM.FilmstripInstance;

  context.empty();

  var pLength = json.length;
  var photo;
  for (var i = 0; i < pLength; i++) {
    photo = json[i]['photo'];
    new IMM.Filmstrip.Photo(photo.url);
  }
  console.log(IMM.FilmstripInstance);
};

IMM.Filmstrip.prototype.empty = function(){
  $(this.displayNode).children().fadeOut();
};

IMM.Filmstrip.prototype.addPhoto = function(photo){
  this.photos.push(photo);
  this.displayNode.appendChild(photo.displayNode);
};

IMM.Filmstrip.prototype.onLoadAlbumError = function() {
};

IMM.Filmstrip.Photo = function(url){
  this.url = url;
  this.displayNode = document.createElement("div");
  this.displayNode.innerHTML = ["<img src='", url, "'>"].join('');
  this.displayNode.className = "photo";
  IMM.FilmstripInstance.addPhoto(this);
};


IMM.Album = function(displayNode){
  this.displayNode = displayNode;
  var context = this;
  $(this.displayNode).click(context.onClick);
};

IMM.Album.prototype.onClick = function(e){
  console.log(e);
};


IMM.AlbumGallery = function(){

};

$(document).ready(function() {

  // save off the singleton
  IMM.FilmstripInstance = new IMM.Filmstrip();

  $(".album").click(function(){
    IMM.FilmstripInstance.loadAlbum($(this).attr("data-id"));
  });

//  setTimeout(function() {
//    $("#prompt").fadeOut(3000, function() {
//      $("#source").css("top", $("#tray").height());
//      $("#source").fadeIn();
//      $("#tray").slideDown();
//    });
//  }, 1000);
//
//  $('img').draggable({revert:true, zIndex:10, helper: function() {
//    var new_img = document.createElement("img");
//    $(new_img).css("opacity", 0.3);
//    new_img.src = this.src;
//    return new_img;
//  }});
//
//  $(".facebook.album").droppable({
//    hoverClass: "dropVisual",
//    drop: function(event, ui) {
//      $.post("/page/move_to_fb", {id: $(this).attr("data-album-id"), url: ui.draggable[0].src});
//      var context = this;
//      $(context).animate({backgroundColor:"yellow"}, {duration:100, complete:function() {
//        $(context).animate({backgroundColor:"#3B5998"}, {duration:100, complete:function() {
//          $(context).animate({backgroundColor:"yellow"}, {duration:100, complete:function() {
//            $(context).animate({backgroundColor:"#3B5998"}, {duration:100});
//          }});
//        }});
//      }});
//    }
//  });

});
