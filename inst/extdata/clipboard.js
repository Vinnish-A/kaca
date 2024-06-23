var CLIPBOARD = new CLIPBOARD_CLASS("my_canvas", true);

/**
 * image pasting into canvas
 *
 * @param {string} canvas_id - canvas id
 * @param {boolean} autoresize - if canvas will be resized
 */
function CLIPBOARD_CLASS(canvas_id, autoresize) {
    var _self = this;
    var canvas = document.getElementById(canvas_id);
    var ctx = document.getElementById(canvas_id).getContext("2d");

    //handlers
    document.addEventListener('paste', function (e) {
        _self.paste_auto(e);
    }, false);

    this.getExtension = function (filename) {
        const index = filename.lastIndexOf('.');
        return index !== -1 ? filename.substring(index + 1) : null;
    }

    //draw pasted image to canvas
    this.paste_createImage = function (source, ext) {
        var pastedImage = new Image();

        pastedImage.onload = function () {
            if (autoresize == true) {
                //resize
                canvas.width = pastedImage.width;
                canvas.height = pastedImage.height;
                Shiny.setInputValue("imageInfos", {width: canvas.width, height: canvas.height, extension: ext});
            } else {
                //clear canvas
                ctx.clearRect(0, 0, canvas.width, canvas.height);
            }
            ctx.drawImage(pastedImage, 0, 0);
        }
        ;
        pastedImage.src = source;
        // console.log(pastedImage.src)
    };

//draw pasted link to canvas
    this.paste_link2image = function (source, ext) {
        var pastedImage = new Image();

        pastedImage.onload = function () {
            if (autoresize == true) {
                //resize
                canvas.width = pastedImage.width;
                canvas.height = pastedImage.height;
                Shiny.setInputValue("imageInfos", {width: canvas.width, height: canvas.height, extension: ext});
            } else {
                //clear canvas
                ctx.clearRect(0, 0, canvas.width, canvas.height);
            }
            ctx.drawImage(pastedImage, 0, 0);
        };
        pastedImage.src = source;
        Shiny.setInputValue("src", source)
    };

//on paste
    this.paste_auto = function (e) {
        if (e.clipboardData) {
            var items = e.clipboardData.items;
            if (!items) return;

            //access data directly
            var is_image = false;
            for (var i = 0; i < items.length; i++) {
                if (items[i].type.indexOf("image") !== -1) {
                    //image
                    var blob = items[i].getAsFile();
                    var URLObj = window.URL || window.webkitURL;
                    var source = URLObj.createObjectURL(blob);
                    var ext = _self.getExtension(blob.name)
                    _self.paste_createImage(source, ext);
                    is_image = true;
                    e.preventDefault();
                    Shiny.setInputValue("placeholder", 1);
                    return;
                }
            }

            var is_link = false;
            for (let i = 0; i < items.length; i++) {
                if (items[i].type.indexOf("text/plain") !== -1) {
                    function getAsStringAsync() {
                        return new Promise(function (resolve, reject) {
                            items[i].getAsString(function (str) {
                                resolve(str);
                            });
                        });
                    }

                    async function processAsync() {
                        try {
                            var source = await getAsStringAsync();
                            var ext = _self.getExtension(source);
                            if (ext.length > 4) {

                                async function getContentType(url) {
                                    try {
                                        const response = await fetch(url);
                                        const contentType = response.headers.get('content-type');
                                        if (contentType.startsWith('image/')) {
                                            return contentType.split('/')[1];
                                        } else {
                                            return 'unknown';
                                        }
                                    } catch (error) {
                                        console.error('Error fetching image:', error);
                                        return null;
                                    }
                                }

                                getContentType(source).then(extension => {
                                    console.log('ext1: ', extension);
                                    _self.paste_link2image(source, extension);
                                });

                            } else {

                                _self.paste_link2image(source, ext);

                            }

                        } catch (error) {
                            console.error('Error fetching string:', error);
                        }
                    }

                    processAsync();
                    e.preventDefault();
                    Shiny.setInputValue("placeholder", 2);
                    return;
                }
            }
        }
    };
}

document.addEventListener('DOMContentLoaded', function () {
    const saveButton = document.getElementById('saveButton');
    saveButton.addEventListener('click', function () {
        const canvas = document.getElementById('my_canvas');
        const dataURL = canvas.toDataURL('image/png');

        Shiny.setInputValue("base64", dataURL);
        /*
        console.log(dataURL)

        const downloadLink = document.createElement('a');
        downloadLink.href = dataURL;
        downloadLink.download = 'image.png';

        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);
        */
    });
});
