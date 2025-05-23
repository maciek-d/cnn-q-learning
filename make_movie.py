import os
# -aspect 16:9 ,-y
# Super Mario Bros (E)-
os.system("ffmpeg -r 60 -i \"./snaps/%d.png\" -aspect 16:9 -vf scale=iw*4:-1:flags=neighbor+bitexact+accurate_rnd+full_chroma_int+full_chroma_inp+print_info -preset fast -vcodec libx264 -crf 0 movie2.mp4")