var IMM = {};

IMM.Filmstrip = function() {

  this.photos = [];

  this.displayNode = $("#filmstrip")[0];

};

IMM.Filmstrip.prototype.loadAlbum = function(id) {
  if (album.photos != null) {
    this.empty();
    var photo;
    var pLength = album.photos.length;
    for (var i = 0; i < pLength; i++) {
      photo = album.photos[i];
      new IMM.Filmstrip.photo(photo.url);
    }
  }
};

IMM.Filmstrip.prototype.onLoadAlbumSuccess = function(json, httpCode, xmlHttpRequest) {
};

IMM.Filmstrip.prototype.empty = function() {
  $(this.displayNode).children().fadeOut();
};

IMM.Filmstrip.prototype.addPhoto = function(photo) {
  this.photos.push(photo);
  this.displayNode.appendChild(photo.displayNode);
};

IMM.Filmstrip.prototype.onLoadAlbumError = function() {
};

IMM.Filmstrip.Photo = function(url) {
  this.url = url;
  this.displayNode = document.createElement("div");
  this.displayNode.innerHTML = ["<img src='", url, "'>"].join('');
  this.displayNode.className = "photo";
  IMM.FilmstripInstance.addPhoto(this);

  var context = this;
  $(this.displayNode).draggable({revert:true, zIndex:10,
    helper: function() {
      var new_img = document.createElement("img");
      $(new_img).css("opacity", 0.3);
      var template = $(context.displayNode).children("img");
      new_img.src = template.attr("src");
      new_img.style.height = template.css("height");
      return new_img;
    }
  });
};


IMM.Album = function(displayNode) {
  this.displayNode = displayNode;
  this.photos = null;
  this.id = $(this.displayNode).attr("data-id");

  var context = this;

  if ($(this.displayNode).find("img").hasClass("spinner")) {
    $.ajax({
      type: 'GET',
      url: "/page/load_album_images?id=" + context.id,
      success: function(json, httpCode, xmlHttpRequest){
        context.onLoadAlbumSuccess(json, httpCode, xmlHttpRequest);
      },
      dataType: "json",
      error: context.onLoadAlbumError
    });
  } else {
    var context = this;
    $(this.displayNode).find("img").ready(function(){
      IMM.ResizeSquare($(context.displayNode).find("img"));
    });
  }

  $(this.displayNode).droppable({
    hoverClass: "dropVisual",
    drop: function(event, ui) {
//      $.post("/page/move", {id: $(this).attr("data-id"), url: ui.draggable[0].src});
      $(context.displayNode).animate({backgroundColor:"yellow"}, {duration:100, complete:function() {
        $(context.displayNode).animate({backgroundColor:"#fff"}, {duration:100, complete:function() {
          $(context.displayNode).animate({backgroundColor:"yellow"}, {duration:100, complete:function() {
            $(context.displayNode).animate({backgroundColor:"#fff"}, {duration:100});
          }});
        }});
      }});
    }
  });
};

IMM.Album.prototype.onLoadAlbumSuccess = function(json, httpCode, xmlHttpRequest){
  var pLength = json.length;
  var photo;
  this.photos = [];
  for (var i = 0; i < pLength; i++) {
    photo = json[i]['photo'];
    this.photos.push(photo);
    if ($(this.displayNode).find('img').hasClass('spinner')) {
      $(this.displayNode).find('img').hide();
      $(this.displayNode).find('img').attr("src", photo.url);
      $(this.displayNode).find('img').removeClass('spinner');
      $(this.displayNode).find('img').load(function(){
        IMM.ResizeSquare(this);
        $(this).show();
      });
    }
  }
//  new IMM.Filmstrip.Photo(photo.url);
};

IMM.Album.prototype.onLoadAlbumError = function(){
};

IMM.Album.prototype.onClick = function(e) {
  console.log(e);
};


IMM.AlbumGallery = function() {
  IMM.FilmstripInstance.loadAlbum(this);
};

IMM.ResizeSquare = function(element){
  element = $(element);
  if (!element.hasClass('spinner')) {
    var sizeNode = document.createElement('img');
    sizeNode.src = element.attr("src");
    $(sizeNode).appendTo("#stage");
    var height = sizeNode.offsetHeight;
    var width = sizeNode.offsetWidth;
    if (height > width) {
      element.css('width', '133px');
    } else {
      element.css('height', '133px');
    }
  }
};

$(document).ready(function() {

  // save off the singleton
  IMM.FilmstripInstance = new IMM.Filmstrip();

  $(".album").each(function(){
    new IMM.Album(this);
  });

  $(".album").click(function() {
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
