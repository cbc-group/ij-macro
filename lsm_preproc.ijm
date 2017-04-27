macro "LSM PreProcess" {
	print("\\Clear");
	run("Close All");

    // select a folder
    dir = getDirectory("Choose a Directory");

    // default value
    pixelSize = 0.108;
    zInterval = 0.3;

    // dialog
    Dialog.create("Parameters");
    Dialog.addNumber("Pixel size (nm):", pixelSize);
    Dialog.addNumber("Z interval (nm):", zInterval);
    Dialog.show();
    // extract variables
    pixelSize = Dialog.getNumber();
    zInterval = Dialog.getNumber();

    rescaleFactor = zInterval/pixelSize;

	setBatchMode(true);
	
    dimension = openAsLinearStack(dir);
    processLinearStack(dir, dimension, rescaleFactor);

    setBatchMode(false);
}

function openAsLinearStack(dir) {
    fileList = listTiffFiles(dir);

    for (i = 0; i < fileList.length; i++) {
    	showProgress(i, fileList.length);
    	
    	fileName = fileList[i];
    	open(fileName);
        if (i == 0) {
            rename("Concat");
        } else {
            run("Concatenate...", "  title=Concat image1=Concat image2=" + getTitle() + " image3=[-- None --]");
        }
    }

    dimension = analyzeDimension(fileList);
    print(" - Channels: " + dimension[0]);
    print(" - Slices: " + dimension[1]);
    print(" - Frames: " + dimension[2]);

    return dimension;
}

function listTiffFiles(dir) {
    fullList = getFileList(dir);

    tiffList = newArray(0);
    for (i = 0; i < fullList.length; i++) {
        fileName = fullList[i];
        if (endsWith(fileName, ".tif")) {
            tiffList = Array.concat(tiffList, fileName);
        }
    }
    return tiffList;
}

function analyzeDimension(fileList) {
    channels = updateChannels(fileList);

	// update slices, rest of the variables are dummies
    getDimensions(w, h, c, slices, f);

    // update frame count
    frames = fileList.length/channels;

    // slices is the summed result, revert back
    slices = slices / (channels*frames);

    return newArray(channels, slices, frames);
}

function updateChannels(fileList) {
    channels = -1;

    for (i = 0; i < fileList.length; i++) {
        fileName = getFilename(fileList[i]);
        token = split(fileName, "_");
        currentChannel = parseInt(substring(token[1], 2));
        if (currentChannel > channels) {
            channels = currentChannel;
        };
    }

    return (channels+1);
}

function getFilename(name) {
	dotIndex = indexOf(name, ".");
	return substring(name, 0, dotIndex);
}

function processLinearStack(dir, dimension, rescaleFactor) {
    // expand the variable list
    channels = dimension[0];
    slices = dimension[1];
    frames = dimension[2];

    // convert from flat stack to hyperstack
    run("Stack to Hyperstack...", "order=xyztc channels=" + channels + " slices=" + slices + " frames=" + frames + " display=Composite");

    // ask for color sequence
    run("Arrange Channels...");

	// rename the primary image source
    rename("Hyperstack");

    // perform the projections
    selectWindow("Hyperstack");
	print("Generating XY view");
    xyMIP();
    path = generateOutputTiffPath(dir, "xy");
    saveAs("Tiff", path);
    
	selectWindow("Hyperstack");
    print("Generating XZ view");
    xzMIP(rescaleFactor);
    path = generateOutputTiffPath(dir, "xz");
    saveAs("Tiff", path);
    
	selectWindow("Hyperstack");
    print("Generating YZ view");
    yzMIP(rescaleFactor);
    path = generateOutputTiffPath(dir, "yz");
    saveAs("Tiff", path);

    close("Hyperstack");
}

function xyMIP() {
    run("Z Project...", "projection=[Max Intensity] all");
    rename("XY Projection");

    // show the result
    setBatchMode("show");
}

function xzMIP(rescaleFactor) {
    run("Reslice [/]...", "output=1.000 start=Top avoid");
    rename("Reslice");
    run("Z Project...", "projection=[Max Intensity] all");
    rename("Project");
    run("Scale...", "x=1.0 y=" + rescaleFactor + " z=1.0 interpolation=Bilinear average create title=XZ Projection");

	// cleanup intermediate images
	close("Reslice");
	close("Project");

	// show the result
    setBatchMode("show");
}

function yzMIP(rescaleFactor) {
    run("Reslice [/]...", "output=1.000 start=Left rotate avoid");
    rename("Reslice");
    run("Z Project...", "projection=[Max Intensity] all");
    rename("Project");
    run("Scale...", "x=" + rescaleFactor + " y=1.0 z=1.0 interpolation=Bilinear average create title=YZ Projection");

	// cleanup intermediate images
	close("Reslice");
	close("Project");

	// show the result
    setBatchMode("show");
}

function generateOutputTiffPath(dir, suffix) {
    parentDir = File.getParent(dir);
    projectName = File.getName(dir);

    return parentDir + File.separator + projectName + "_" + suffix + ".tif";
}
