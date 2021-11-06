#include<windows.h>
#include<cstudio>

#define OPEN_FILE_BUTTON 1
#define SAVE_FILE_BUTTON 2

LRESULT CALLBACK WindowProcedure(HWND, UINT, WPARAM, LPARAM);

void AddControls(HWND);

HWND hMainWindow, hEdit;

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE hPrevInst, LPSTR args, int nCmdShow) {
    WNDCLASS wc = {0};

    wc.hbrBackground = (HBRUSH) COLOR_WINDOW;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hInstance = hInst;
    wc.lpszClassName = reinterpret_cast<LPCSTR>(L"myWindowClass");
    wc.lpfnWndProc = WindowProcedure;

    if (!RegisterClassW(reinterpret_cast<const WNDCLASSW *>(&wc)))
        return -1;

    hMainWindow = CreateWindowW(L"myWindowClass", L"My Window", WS_OVERLAPPEDWINDOW | WS_VISIBLE, 100, 100, 500, 500,
                                nullptr, nullptr, nullptr, nullptr);

    MSG msg = {nullptr};

    while (GetMessage(&msg, nullptr, NULL, NULL)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return 0;
}

void display_file(char *path) {
    FILE *file;
    file = fopen(path, "rb");
    fseek(file, 0, SEEK_END);
    int _size = ftell(file);
    rewind(file);
    char *data = new char[_size + 1];
    fread(data, _size, 1, file);
    // '\0' is terminating character
    data[_size] = '\0';

    SetWindowText(hEdit, data);

    fclose(file);
}

void open_file(HWND hwnd) {
    OPENFILENAME ofn;

    char file_name[100];

    ZeroMemory(&ofn, sizeof(OPENFILENAME));

    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = hwnd;
    ofn.lpstrFile = file_name;
    ofn.lpstrFile[0] = '\0';
    ofn.nMaxFile = 100;
    ofn.lpstrFilter = "All file\0*.*\0Source Files\0*.CPP\0Text Files\0*.TXT\0";
    ofn.nFilterIndex = 1;

    GetOpenFileName(&ofn);

    display_file(ofn.lpstrFile);

    //Path of file show on Dialog Box
    //MessageBox(hwnd, NULL, ofn.lpstrFile, MB_OK);
}

void write_file(char *path) {
    FILE *file;
    file = fopen(path, "w");

    int _size = GetWindowTextLength(hEdit);
    char *data = new char[_size + 1];
    GetWindowText(hEdit, data, _size + 1);

    fwrite(data, _size + 1, 1, file);

    fclose(file);

}

void save_file(HWND hwnd) {
    OPENFILENAME ofn;

    char file_name[100];

    ZeroMemory(&ofn, sizeof(OPENFILENAME));

    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = hwnd;
    ofn.lpstrFile = file_name;
    ofn.lpstrFile[0] = '\0';
    ofn.nMaxFile = 100;
    ofn.lpstrFilter = "All file\0*.*\0Source Files\0*.CPP\0Text Files\0*.TXT\0";
    ofn.nFilterIndex = 1;

    GetSaveFileName(&ofn);

    write_file(ofn.lpstrFile);
}


LRESULT CALLBACK WindowProcedure(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
        case WM_COMMAND: {
            switch (wp) {
                case OPEN_FILE_BUTTON:
                    open_file(hwnd);
                    break;
                case SAVE_FILE_BUTTON:
                    save_file(hwnd);
                    break;
                default:
                    return 0;
            }
        }
            break;
        case WM_CREATE:
            AddControls(hwnd);
            break;
        case WM_DESTROY:
            PostQuitMessage(0);
            break;
        default:
            return DefWindowProcW(hwnd, msg, wp, lp);

    }
    return 0;
}

void AddControls(HWND hwnd) {
    CreateWindowW(L"Button", L"Open File", WS_VISIBLE | WS_CHILD, 10, 10, 150, 36, hwnd, (HMENU) OPEN_FILE_BUTTON,
                  nullptr, nullptr);
    CreateWindowW(L"Button", L"Save File", WS_VISIBLE | WS_CHILD, 170, 10, 150, 36, hwnd, (HMENU) SAVE_FILE_BUTTON,
                  nullptr, nullptr);

    hEdit = CreateWindowW(L"Edit", L"", WS_VISIBLE | WS_CHILD | ES_MULTILINE | WS_BORDER | WS_VSCROLL | WS_HSCROLL, 10,
                          50, 400, 300,
                          hwnd, nullptr, nullptr, nullptr);

}