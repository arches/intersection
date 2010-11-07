var IMM = {};

IMM.Filmstrip = function() {
  this.photos = [];
  this.displayNode = $("#filmstrip")[0];
  this.slider = $("#filmstrip .slider")[0];
};

IMM.Filmstrip.prototype.loadAlbum = function(id) {
  if ($(this.displayNode).css("display") == "none") {
    $(this.displayNode).fadeIn();
  }
  var album = IMM.Albums[id];
  if (album.photos != null) {
    this.empty();
    var photo;
    var pLength = album.photos.length;
    for (var i = 0; i < pLength; i++) {
      photo = album.photos[i];
      new IMM.Filmstrip.Photo(photo.id, photo.url);
    }
    $("#filmstrip .spinner").hide();
    $("#filmstrip .slider").show();
  } else {
    this.empty();
    var context = this;
    album.load(function() {
      context.loadAlbum(id); // try again
    }); // wouldn't have to do this if we passed the json on initial load. we often have it.
  }
};

IMM.Filmstrip.prototype.empty = function() {
  $("#filmstrip .slider").hide();
  $("#filmstrip .spinner").show();
  $("#filmstrip .slider").children().remove();
};

IMM.Filmstrip.prototype.addPhoto = function(photo) {
  this.photos.push(photo);
  $("#filmstrip .slider")[0].appendChild(photo.displayNode);
};

IMM.Filmstrip.prototype.onLoadAlbumError = function() {
};

IMM.Filmstrip.Photo = function(id, url) {
  this.url = url;
  this.displayNode = document.createElement("div");
  this.displayNode.innerHTML = ["<img src='", url, "' data-id='", id, "'>"].join('');
  this.displayNode.className = "photo";
  IMM.FilmstripInstance.addPhoto(this);

  var context = this;
  $(this.displayNode).draggable({revert:true, zIndex:10, appendTo: 'body',
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
  this.provider = $(this.displayNode).parents(".account").attr("data-provider");
  this.name = $(this.displayNode).find(".info").attr('data-name');

  var context = this;

  if ($(this.displayNode).find("img").hasClass("spinner")) {
    this.load();
  } else {
    var context = this;
    $(this.displayNode).find("img").load(function() {

      IMM.ResizeSquare($(context.displayNode).find("img"));
    });
  }

  $(this.displayNode).droppable({
    hoverClass: "dropVisual",
    drop: function(event, ui) {
      $.post("/page/move", {id: $(this).attr("data-id"), url: ui.draggable.find("img").attr("src"), photo_id: ui.draggable.find("img").attr("data-id")});
      context.photos = null; // force a refresh next time
      if (context.provider == "flickr") {
        for (var i in IMM.Albums) {
          var album = IMM.Albums[i];
          if (album.provider == "flickr" && album.name == "Photostream") {
            album.photos = null;
          }
        }
      }
      $(context.displayNode).css("background", "#90ee90");  // keep the hover color
      $(context.displayNode).animate({backgroundColor:"green"}, {duration:300, complete:function() {
        $(context.displayNode).animate({backgroundColor:"#fff"}, {duration:1000, complete:function(){
          $(context.displayNode).css("background", null);
        }});
      }});
    }
  });
};

IMM.Album.prototype.load = function(callback) {
  var context = this;
  var cb = callback;
  $.ajax({
    type: 'GET',
    url: "/page/load_album_images?id=" + context.id,
    success: function(json, httpCode, xmlHttpRequest, callback) {
      context.onLoadAlbumSuccess(json, httpCode, xmlHttpRequest);
      if (cb) {
        cb.call();
      }
    },
    error: function(json, httpCode, xmlHttpRequest, callback) {
      context.onLoadAlbumError(json, httpCode, xmlHttpRequest);
    },
    dataType: "json"
  });
};

IMM.Album.prototype.onLoadAlbumSuccess = function(json, httpCode, xmlHttpRequest) {
  // remove the spinner regardless
  if ($(this.displayNode).find('img').hasClass('spinner')) {
    $(this.displayNode).find('img').hide();
  }

  var pLength = json.length;
  var photo;
  this.photos = [];
  for (var i = 0; i < pLength; i++) {
    photo = json[i]['photo'];
    this.photos.push(photo);
    if ($(this.displayNode).find('img').hasClass('spinner')) {
      $(this.displayNode).find('img').attr("src", photo.url);
      $(this.displayNode).find('img').removeClass('spinner');
      $(this.displayNode).find('img').load(function() {
        IMM.ResizeSquare(this);
        $(this).show();
      });
    }
  }
};

IMM.Album.prototype.onLoadAlbumError = function() {
  if ($(this.displayNode).find('img').hasClass('spinner')) {
    $(this.displayNode).find('img').hide();
  }
};

IMM.Album.prototype.onClick = function(e) {
  console.log(e);
};


IMM.AlbumGallery = function() {
  IMM.FilmstripInstance.loadAlbum(this);
};

IMM.ResizeSquare = function(element) {
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
  IMM.Albums = {};

  $(".album").each(function() {
    IMM.Albums[$(this).attr("data-id")] = new IMM.Album(this);
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
