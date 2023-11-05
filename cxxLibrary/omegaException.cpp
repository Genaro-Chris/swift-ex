#include <stacktrace>
#include <source_location>
#include <string>

using namespace std;

template <typename DATA_T>
class OmegaException
{
private:
    string err_str;
    DATA_T user_data;
    const source_location location;
    const stacktrace backtrace_;

public:
    OmegaException(string str, DATA_T data, const source_location &loc = source_location::current(), stacktrace trace = stacktrace::current()) : err_str(std::move(str)), user_data(std::move(data)), location(std::move(loc)), backtrace_(std::move(trace)) {}
    ~OmegaException();

    string &what() { return err_str; }
    const string &what() const noexcept { return err_str; }
    const source_location &where() const noexcept { return location; }
    const stacktrace &stack() const noexcept { return backtrace_; }
    DATA_T &data() { user_data; }
    const DATA_T &data() const noexcept { return user_data; }
};
