macro "Split LIF" {
	// clear the log
	print("\\Clear");
	
    // ask user for file if no option is passed in
    path = File.openDialog("Choose a File");

    // use file name as directory name
    file = File.getName(path);
    index = indexOf(file, ".");
    dir = substring(file, 0, index);
    // update the directory location
    dir = File.getParent(path) + File.separator + dir;
    // check the existance
    if (File.exists(dir)) {
        exit("Output directory exists")
    }
    // create the container
    File.makeDirectory(dir);
    if (!File.exists(dir)) {
        exit("Unable to create directory");
    }

    setBatchMode(true);
    start = getTime();

    // open the file
    print("Reading \"" + file + "\"");
    run("Bio-Formats Windowless Importer", "open=[" + path + "]");

    // ensure we have processed all the series
    series = nImages();
    print(" - Series: " + series);
    print("\n");

    for (i = 1; i <= series; i++) {
        // select specific series
        selectImage(i);
        print("Series " + i);

        // get the dimension info
        getDimensions(width, height, channels, slices, frames);
        print(" - Size: " + width + "x" + height);
        print(" - Channels: " + channels);
        print(" - Slices: " + slices);
        print(" - Frames: " + frames);

        // re-arrange the channels
        print("Re-arranging dimensions...");
        run("Hyperstack to Stack");
        run("Stack to Hyperstack...", "order=xyzct channels=" + channels + " slices=" + slices + " frames=" + frames);

        // split the stack to different stacks
        for (t = 1; t <= frames; t++) {
            print("Splitting frame " + t);

            run("Make Substack...", "slices=1-" + slices + " frames=" + t);
            run("Save", "save=[" + dir + File.separator + "s" + i + "_t" + t + ".tif]");
            close();
        }

        close();
        print("\n");
    }

    end = getTime();
    setBatchMode(false);

    interval = (end-start)/1000;
    print("Done, " + interval + "s elapsed");
    print("\n");
}
